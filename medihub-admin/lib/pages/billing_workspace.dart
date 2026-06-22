import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';
import '../core/billing_print_helper.dart';

class BillingWorkspace extends StatefulWidget {
  final AdminApiService service;

  const BillingWorkspace({super.key, required this.service});

  @override
  State<BillingWorkspace> createState() => _BillingWorkspaceState();
}

class _BillingWorkspaceState extends State<BillingWorkspace> {
  final searchController = TextEditingController();
  String status = 'UNPAID';
  List<Map<String, dynamic>> rows = [];
  Map<String, dynamic>? selected;
  bool loading = true;
  bool busy = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> load({bool preserveSelection = true}) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final search = searchController.text.trim();
      final results = await Future.wait([
        widget.service.loadBillingInvoices(search: search, status: status),
        widget.service.searchBillingVisits(search),
      ]);
      final invoices = results[0];
      final visits = results[1];
      final invoicesByVisit = <String, Map<String, dynamic>>{
        for (final invoice in invoices) invoice['visitId'].toString(): invoice,
      };
      final merged = <Map<String, dynamic>>[
        ...invoices.map((invoice) => {...invoice, 'invoice': invoice}),
        if (status == 'UNPAID' || status == 'ALL')
          ...visits
              .where(
                (visit) => !invoicesByVisit.containsKey(visit['id'].toString()),
              )
              .map(
                (visit) => {
                  'id': 'visit-${visit['id']}',
                  'visitId': visit['id'],
                  'visitCode': visit['visitCode'],
                  'patientId': visit['patientId'],
                  'patientCode': visit['patientCode'],
                  'patient': visit['patient'],
                  'patientPhone': visit['patientPhone'],
                  'status': 'NOT_GENERATED',
                  'totalAmount': 0,
                  'insurancePayAmount': 0,
                  'patientPayAmount': 0,
                  'discountAmount': 0,
                  'paidAmount': 0,
                  'items': const [],
                  'invoice': null,
                },
              ),
      ];
      final selectedId = preserveSelection && selected != null
          ? selected!['id']
          : null;
      if (!mounted) return;
      setState(() {
        rows = merged;
        selected = rows.isEmpty
            ? null
            : rows.firstWhere(
                (item) => item['id'] == selectedId,
                orElse: () => rows.first,
              );
      });
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> generate() async {
    final row = selected;
    if (row == null) return;
    setState(() => busy = true);
    try {
      final invoice = await widget.service.generateBillingInvoice(
        row['visitId'].toString(),
      );
      showMessage('Đã tạo/cập nhật bảng kê ${invoice['invoiceCode']}');
      await load(preserveSelection: false);
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pay() async {
    final invoice = selected?['invoice'];
    if (invoice is! Map) return;
    final data = Map<String, dynamic>.from(invoice);
    final remaining = remainingAmount(data);
    final amountController = TextEditingController(text: '$remaining');
    final discountController = TextEditingController(
      text: '${data['discountAmount'] ?? 0}',
    );
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thu tiền ${data['invoiceCode']}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Miễn giảm',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền thu',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'amount': parseAmount(amountController.text),
              'discountAmount': parseAmount(discountController.text),
            }),
            child: const Text('Xác nhận thu'),
          ),
        ],
      ),
    );
    amountController.dispose();
    discountController.dispose();
    if (payload == null) return;
    setState(() => busy = true);
    try {
      final updated = await widget.service.payBillingInvoice(
        data['id'].toString(),
        payload,
      );
      showMessage(
        updated['status'] == 'PAID'
            ? 'Hóa đơn đã thanh toán đủ'
            : 'Đã ghi nhận thanh toán một phần',
      );
      await load(preserveSelection: false);
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> cancelInvoice() async {
    final invoice = selected?['invoice'];
    if (invoice is! Map) return;
    setState(() => busy = true);
    try {
      await widget.service.cancelBillingInvoice(invoice['id'].toString());
      showMessage('Đã hủy hóa đơn');
      await load(preserveSelection: false);
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> printStatement({required bool receipt}) async {
    final invoice = selected?['invoice'];
    if (invoice is! Map) return;
    try {
      final data = await widget.service.loadBillingPrint(
        invoice['id'].toString(),
      );
      openBillingCostStatement(
        data: {
          ...data,
          'documentTitle': receipt ? 'BIÊN LAI THU TIỀN' : 'BẢNG KÊ CHI PHÍ',
        },
        organizationName: widget.service.organizationName,
      );
    } catch (error) {
      showMessage(error.toString(), error: true);
    }
  }

  void showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        toolbar(),
        filters(),
        if (errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade50,
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1100) {
              return Column(
                children: [invoiceList(), const SizedBox(height: 6), detail()],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 45, child: invoiceList()),
                const SizedBox(width: 6),
                Expanded(flex: 55, child: detail()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget toolbar() {
    final invoice = selected?['invoice'];
    final invoiceStatus = invoice is Map ? invoice['status']?.toString() : null;
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            toolButton(
              'Tạo bảng kê',
              Icons.receipt_long_outlined,
              selected != null,
              generate,
            ),
            toolButton(
              'Thu tiền',
              Icons.payments_outlined,
              ['UNPAID', 'PARTIALLY_PAID'].contains(invoiceStatus),
              pay,
            ),
            toolButton(
              'In bảng kê',
              Icons.print_outlined,
              invoice != null,
              () => printStatement(receipt: false),
            ),
            toolButton(
              'In biên lai',
              Icons.receipt_outlined,
              invoiceStatus == 'PAID',
              () => printStatement(receipt: true),
            ),
            toolButton(
              'Hủy hóa đơn',
              Icons.cancel_outlined,
              invoiceStatus == 'UNPAID',
              cancelInvoice,
            ),
          ],
        ),
      ),
    );
  }

  Widget toolButton(
    String label,
    IconData icon,
    bool enabled,
    VoidCallback action,
  ) => InkWell(
    onTap: enabled && !busy ? action : null,
    child: Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFCBD5E1))),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: enabled ? const Color(0xFF0F172A) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: enabled ? const Color(0xFF0F172A) : Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );

  Widget filters() => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFCBD5E1)),
    ),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 380,
          child: TextField(
            controller: searchController,
            onSubmitted: (_) => load(preserveSelection: false),
            decoration: InputDecoration(
              hintText: 'Tìm mã lượt khám / mã BN / tên / SĐT',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => load(preserveSelection: false),
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'UNPAID', child: Text('Chưa thanh toán')),
              DropdownMenuItem(
                value: 'PARTIALLY_PAID',
                child: Text('Thanh toán một phần'),
              ),
              DropdownMenuItem(value: 'PAID', child: Text('Đã thanh toán')),
              DropdownMenuItem(value: 'CANCELLED', child: Text('Đã hủy')),
              DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
            ],
            onChanged: (value) {
              setState(() => status = value ?? 'UNPAID');
              load(preserveSelection: false);
            },
          ),
        ),
      ],
    ),
  );

  Widget invoiceList() => panel(
    'Danh sách bệnh nhân / hóa đơn',
    rows.isEmpty
        ? const SizedBox(
            height: 220,
            child: Center(child: Text('Không có dữ liệu phù hợp')),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 46,
              columns: const [
                DataColumn(label: Text('Mã lượt')),
                DataColumn(label: Text('Mã BN')),
                DataColumn(label: Text('Họ tên')),
                DataColumn(label: Text('Tổng tiền')),
                DataColumn(label: Text('BN trả')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: rows.map((item) {
                return DataRow(
                  selected: item['id'] == selected?['id'],
                  onSelectChanged: (_) => setState(() => selected = item),
                  cells: [
                    DataCell(Text(item['visitCode']?.toString() ?? '')),
                    DataCell(Text(item['patientCode']?.toString() ?? '')),
                    DataCell(Text(item['patient']?.toString() ?? '')),
                    DataCell(Text(money(item['totalAmount']))),
                    DataCell(Text(money(item['patientPayAmount']))),
                    DataCell(statusPill(item['status']?.toString() ?? '')),
                  ],
                );
              }).toList(),
            ),
          ),
  );

  Widget detail() {
    final row = selected;
    if (row == null) {
      return panel(
        'Bảng kê chi phí',
        const SizedBox(
          height: 300,
          child: Center(child: Text('Chọn lượt khám hoặc hóa đơn')),
        ),
      );
    }
    final items = row['items'] as List? ?? const [];
    return panel(
      'Bảng kê chi phí',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFEFF6FF),
            child: Wrap(
              spacing: 20,
              runSpacing: 6,
              children: [
                info('Mã lượt', row['visitCode']),
                info('Mã BN', row['patientCode']),
                info('Bệnh nhân', row['patient']),
                info('SĐT', row['patientPhone']),
                info('Mã hóa đơn', row['invoiceCode']),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Chưa tạo bảng kê cho lượt khám này')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 42,
                columns: const [
                  DataColumn(label: Text('Dịch vụ / thuốc')),
                  DataColumn(label: Text('Số lượng')),
                  DataColumn(label: Text('Đơn giá')),
                  DataColumn(label: Text('Thành tiền')),
                  DataColumn(label: Text('BHYT trả')),
                  DataColumn(label: Text('BN trả')),
                ],
                rows: items.map((value) {
                  final item = Map<String, dynamic>.from(value as Map);
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(item['itemName']?.toString() ?? ''),
                        ),
                      ),
                      DataCell(Text(item['quantity']?.toString() ?? '')),
                      DataCell(Text(money(item['unitPrice']))),
                      DataCell(Text(money(item['amount']))),
                      DataCell(Text(money(item['insurancePayAmount']))),
                      DataCell(Text(money(item['patientPayAmount']))),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 10),
          summary('Tổng chi phí', row['totalAmount']),
          summary('BHYT trả', row['insurancePayAmount']),
          summary('Miễn giảm', row['discountAmount']),
          summary('BN phải trả', row['patientPayAmount']),
          summary('Đã thu', row['paidAmount']),
          summary('Còn lại', remainingAmount(row), emphasize: true),
        ],
      ),
    );
  }

  Widget summary(String label, dynamic value, {bool emphasize = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      SizedBox(
        width: 180,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
      SizedBox(
        width: 140,
        child: Text(
          money(value),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    ],
  );

  Widget panel(String title, Widget child) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFCBD5E1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          color: const Color(0xFFE2E8F0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Padding(padding: const EdgeInsets.all(8), child: child),
      ],
    ),
  );

  Widget info(String label, dynamic value) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        TextSpan(text: value?.toString() ?? ''),
      ],
    ),
  );

  Widget statusPill(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: switch (value) {
        'PAID' => Colors.green.shade100,
        'CANCELLED' => Colors.red.shade100,
        'PARTIALLY_PAID' => Colors.orange.shade100,
        _ => Colors.blue.shade50,
      },
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      statusText(value),
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );

  int remainingAmount(Map<String, dynamic> data) => [
    0,
    parseAmount(data['patientPayAmount']) -
        parseAmount(data['discountAmount']) -
        parseAmount(data['paidAmount']),
  ].reduce((a, b) => a > b ? a : b);

  int parseAmount(dynamic value) =>
      int.tryParse(value?.toString().replaceAll(RegExp(r'[^\d-]'), '') ?? '') ??
      0;

  String money(dynamic value) {
    final number = parseAmount(value);
    return '${number.toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (match) => '.')} đ';
  }

  String statusText(String value) =>
      const {
        'NOT_GENERATED': 'Chưa tạo bảng kê',
        'UNPAID': 'Chưa thanh toán',
        'PARTIALLY_PAID': 'Thanh toán một phần',
        'PAID': 'Đã thanh toán',
        'CANCELLED': 'Đã hủy',
      }[value] ??
      value;
}
