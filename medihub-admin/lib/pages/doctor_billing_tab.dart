import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';

class DoctorBillingTab extends StatefulWidget {
  final AdminApiService service;
  final String visitId;

  const DoctorBillingTab({
    super.key,
    required this.service,
    required this.visitId,
  });

  @override
  State<DoctorBillingTab> createState() => _DoctorBillingTabState();
}

class _DoctorBillingTabState extends State<DoctorBillingTab> {
  List<Map<String, dynamic>> invoices = [];
  bool loading = true;
  bool busy = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(DoctorBillingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visitId != widget.visitId) load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final rows = await widget.service.loadVisitBilling(widget.visitId);
      if (mounted) setState(() => invoices = rows);
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> generate() async {
    setState(() => busy = true);
    try {
      await widget.service.generateBillingInvoice(widget.visitId);
      await load();
      showMessage('Đã tạo/cập nhật bảng kê viện phí');
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
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
    if (loading) return const LinearProgressIndicator();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Viện phí theo lượt khám',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: busy ? null : generate,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Tạo/Cập nhật bảng kê'),
            ),
          ],
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        const SizedBox(height: 8),
        if (invoices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Chưa có bảng kê viện phí')),
          )
        else
          ...invoices.map(invoiceCard),
      ],
    );
  }

  Widget invoiceCard(Map<String, dynamic> invoice) {
    final items = invoice['items'] as List? ?? const [];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        initiallyExpanded: invoices.length == 1,
        title: Text(
          invoice['invoiceCode']?.toString() ?? '',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${statusText(invoice['status']?.toString() ?? '')} • Còn lại ${money(remaining(invoice))}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowMinHeight: 40,
                    columns: const [
                      DataColumn(label: Text('Dịch vụ / thuốc')),
                      DataColumn(label: Text('SL')),
                      DataColumn(label: Text('Đơn giá')),
                      DataColumn(label: Text('Thành tiền')),
                      DataColumn(label: Text('BHYT trả')),
                      DataColumn(label: Text('BN trả')),
                    ],
                    rows: items.map((value) {
                      final item = Map<String, dynamic>.from(value as Map);
                      return DataRow(
                        cells: [
                          DataCell(Text(item['itemName']?.toString() ?? '')),
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
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    summary('Tổng chi phí', invoice['totalAmount']),
                    summary('BHYT trả', invoice['insurancePayAmount']),
                    summary('Miễn giảm', invoice['discountAmount']),
                    summary('Đã thu', invoice['paidAmount']),
                    summary('Còn lại', remaining(invoice)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget summary(String label, dynamic value) => Text(
    '$label: ${money(value)}',
    style: const TextStyle(fontWeight: FontWeight.w800),
  );

  int remaining(Map<String, dynamic> data) => [
    0,
    amount(data['patientPayAmount']) -
        amount(data['discountAmount']) -
        amount(data['paidAmount']),
  ].reduce((a, b) => a > b ? a : b);

  int amount(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;

  String money(dynamic value) {
    final digits = amount(value).toString();
    return '${digits.replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (match) => '.')} đ';
  }

  String statusText(String value) =>
      const {
        'UNPAID': 'Chưa thanh toán',
        'PARTIALLY_PAID': 'Thanh toán một phần',
        'PAID': 'Đã thanh toán',
        'CANCELLED': 'Đã hủy',
      }[value] ??
      value;
}
