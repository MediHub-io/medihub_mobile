import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';

class PharmacyWorkspace extends StatefulWidget {
  final AdminApiService service;

  const PharmacyWorkspace({super.key, required this.service});

  @override
  State<PharmacyWorkspace> createState() => _PharmacyWorkspaceState();
}

class _PharmacyWorkspaceState extends State<PharmacyWorkspace> {
  String status = 'WAITING_DISPENSE';
  List<Map<String, dynamic>> prescriptions = [];
  Map<String, dynamic>? selected;
  bool loading = true;
  bool busy = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({bool preserveSelection = true}) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final rows = await widget.service.loadPharmacyPrescriptions(
        status: status,
      );
      final selectedId = preserveSelection && selected != null
          ? selected!['id']
          : null;
      if (!mounted) return;
      setState(() {
        prescriptions = rows;
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

  Future<void> dispense() async {
    final row = selected;
    if (row == null) return;
    setState(() => busy = true);
    try {
      await widget.service.dispensePrescription(row['id'].toString());
      showMessage('Đã phát thuốc cho ${row['patient']}');
      await load(preserveSelection: false);
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
            if (constraints.maxWidth < 1050) {
              return Column(
                children: [
                  prescriptionList(),
                  const SizedBox(height: 6),
                  detail(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 45, child: prescriptionList()),
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
    final canDispense = selected?['status'] == 'WAITING_DISPENSE';
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            toolButton(
              'Phát thuốc',
              Icons.medication_liquid_outlined,
              canDispense,
              dispense,
            ),
            toolButton(
              'In đơn',
              Icons.print_outlined,
              selected != null,
              () => showMessage(
                'Đơn ${selected?['prescriptionCode']} đã sẵn sàng để in',
              ),
            ),
            toolButton('Tải lại', Icons.refresh, true, load),
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
  ) {
    return InkWell(
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
  }

  Widget filters() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(
                labelText: 'Trạng thái đơn',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'WAITING_DISPENSE',
                  child: Text('Chờ phát thuốc'),
                ),
                DropdownMenuItem(
                  value: 'DISPENSED',
                  child: Text('Đã phát thuốc'),
                ),
                DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
              ],
              onChanged: (value) {
                setState(() => status = value ?? 'WAITING_DISPENSE');
                load(preserveSelection: false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget prescriptionList() => panel(
    'Danh sách đơn thuốc',
    prescriptions.isEmpty
        ? const SizedBox(
            height: 220,
            child: Center(child: Text('Không có đơn thuốc phù hợp')),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 46,
              columns: const [
                DataColumn(label: Text('Mã đơn')),
                DataColumn(label: Text('Mã BN')),
                DataColumn(label: Text('Bệnh nhân')),
                DataColumn(label: Text('Bác sĩ')),
                DataColumn(label: Text('Số thuốc')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: prescriptions.map((item) {
                final items = item['items'] as List? ?? const [];
                return DataRow(
                  selected: item['id'] == selected?['id'],
                  onSelectChanged: (_) => setState(() => selected = item),
                  cells: [
                    DataCell(Text(item['prescriptionCode']?.toString() ?? '')),
                    DataCell(Text(item['patientCode']?.toString() ?? '')),
                    DataCell(Text(item['patient']?.toString() ?? '')),
                    DataCell(Text(item['doctor']?.toString() ?? '')),
                    DataCell(Text('${items.length}')),
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
        'Chi tiết đơn',
        const SizedBox(
          height: 300,
          child: Center(child: Text('Chọn đơn thuốc để xem chi tiết')),
        ),
      );
    }
    final items = row['items'] as List? ?? const [];
    return panel(
      'Chi tiết đơn',
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
                info('Mã đơn', row['prescriptionCode']),
                info('Mã BN', row['patientCode']),
                info('Bệnh nhân', row['patient']),
                info('Khoa', row['department']),
                info('Bác sĩ', row['doctor']),
                info('Chẩn đoán', row['diagnosis']),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 42,
              columns: const [
                DataColumn(label: Text('Thuốc')),
                DataColumn(label: Text('Liều dùng')),
                DataColumn(label: Text('Tần suất')),
                DataColumn(label: Text('Số ngày')),
                DataColumn(label: Text('Số lượng')),
                DataColumn(label: Text('Đơn vị')),
                DataColumn(label: Text('Cách dùng')),
                DataColumn(label: Text('BHYT')),
                DataColumn(label: Text('Thành tiền')),
              ],
              rows: items.map((value) {
                final item = Map<String, dynamic>.from(value as Map);
                return DataRow(
                  cells: [
                    DataCell(Text(item['medicineName']?.toString() ?? '')),
                    DataCell(Text(item['dosage']?.toString() ?? '')),
                    DataCell(Text(item['frequency']?.toString() ?? '')),
                    DataCell(Text(item['duration']?.toString() ?? '')),
                    DataCell(Text(item['quantity']?.toString() ?? '')),
                    DataCell(Text(item['unit']?.toString() ?? '')),
                    DataCell(Text(item['instruction']?.toString() ?? '')),
                    DataCell(
                      Text(item['insuranceCovered'] == true ? 'Có' : 'Không'),
                    ),
                    DataCell(Text(money(item['amount']))),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tổng tiền: ${money(row['totalAmount'])}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          if (row['note']?.toString().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Ghi chú: ${row['note']}'),
            ),
        ],
      ),
    );
  }

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
      color: value == 'DISPENSED'
          ? Colors.green.shade100
          : Colors.orange.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      value == 'DISPENSED' ? 'Đã phát' : 'Chờ phát',
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );

  String money(dynamic value) {
    final number = num.tryParse(value?.toString() ?? '') ?? 0;
    final digits = number.round().toString();
    return '${digits.replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (match) => '.')} đ';
  }
}
