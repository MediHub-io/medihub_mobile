import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';

class DoctorPrescriptionTab extends StatefulWidget {
  final AdminApiService service;
  final Map<String, dynamic> visit;
  final Map<String, dynamic>? encounter;

  const DoctorPrescriptionTab({
    super.key,
    required this.service,
    required this.visit,
    required this.encounter,
  });

  @override
  State<DoctorPrescriptionTab> createState() => _DoctorPrescriptionTabState();
}

class _DoctorPrescriptionTabState extends State<DoctorPrescriptionTab> {
  List<Map<String, dynamic>> prescriptions = [];
  bool loading = true;
  bool busy = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(DoctorPrescriptionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visit['id'] != widget.visit['id']) load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final rows = await widget.service.loadVisitPrescriptions(
        widget.visit['id'].toString(),
      );
      if (mounted) setState(() => prescriptions = rows);
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openEditor([Map<String, dynamic>? prescription]) async {
    if (widget.encounter == null) {
      showMessage(
        'Cần bắt đầu khám để tạo Encounter trước khi kê đơn',
        error: true,
      );
      return;
    }
    setState(() => busy = true);
    List<Map<String, dynamic>> medicines;
    try {
      medicines = await widget.service.loadMedicines();
    } catch (error) {
      showMessage(error.toString(), error: true);
      if (mounted) setState(() => busy = false);
      return;
    }
    if (mounted) setState(() => busy = false);

    final diagnosis = TextEditingController(
      text:
          prescription?['diagnosis']?.toString() ??
          widget.encounter?['diagnosisText']?.toString() ??
          '',
    );
    final note = TextEditingController(
      text: prescription?['note']?.toString() ?? '',
    );
    final lines = <_PrescriptionLine>[
      for (final value in prescription?['items'] as List? ?? const [])
        _PrescriptionLine.fromMap(Map<String, dynamic>.from(value as Map)),
    ];
    if (lines.isEmpty) lines.add(_PrescriptionLine());

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(
              prescription == null ? 'Tạo đơn thuốc' : 'Sửa đơn thuốc',
            ),
            content: SizedBox(
              width: 1050,
              height: 620,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: diagnosis,
                    decoration: const InputDecoration(
                      labelText: 'Chẩn đoán',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: lines.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final line = lines[index];
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButtonFormField<String>(
                                      initialValue:
                                          medicines.any(
                                            (item) =>
                                                item['id'].toString() ==
                                                line.medicineId,
                                          )
                                          ? line.medicineId
                                          : null,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Thuốc *',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: medicines
                                          .map(
                                            (item) => DropdownMenuItem(
                                              value: item['id'].toString(),
                                              child: Text(
                                                '${item['code'] ?? ''} - ${item['name'] ?? ''}',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) => setDialogState(() {
                                        line.medicineId = value;
                                        final medicine = medicines.firstWhere(
                                          (item) =>
                                              item['id'].toString() == value,
                                        );
                                        line.unit.text =
                                            medicine['unit']?.toString() ?? '';
                                      }),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 2,
                                    child: textField('Liều dùng', line.dosage),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 2,
                                    child: textField(
                                      'Tần suất',
                                      line.frequency,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Xóa dòng',
                                    onPressed: lines.length == 1
                                        ? null
                                        : () => setDialogState(() {
                                            lines.removeAt(index).dispose();
                                          }),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: textField(
                                      'Số ngày',
                                      line.duration,
                                      number: true,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: textField(
                                      'Số lượng *',
                                      line.quantity,
                                      number: true,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: textField(
                                      'Đơn vị',
                                      line.unit,
                                      enabled: false,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 3,
                                    child: textField(
                                      'Cách dùng',
                                      line.instruction,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  SizedBox(
                                    width: 125,
                                    child: CheckboxListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('BHYT'),
                                      value: line.insuranceCovered,
                                      onChanged:
                                          widget.visit['insuranceUsed'] == true
                                          ? (value) => setDialogState(() {
                                              line.insuranceCovered =
                                                  value == true;
                                            })
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        setDialogState(() => lines.add(_PrescriptionLine())),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm thuốc'),
                  ),
                  TextField(
                    controller: note,
                    minLines: 2,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Đóng'),
              ),
              FilledButton.icon(
                onPressed: () {
                  final valid = lines.every(
                    (line) =>
                        line.medicineId != null &&
                        (double.tryParse(line.quantity.text.trim()) ?? 0) > 0,
                  );
                  if (!valid) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng chọn thuốc và nhập số lượng'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, {
                    'encounterId': widget.encounter!['id'],
                    'doctorId':
                        widget.encounter!['doctorId'] ??
                        widget.visit['doctorId'],
                    'diagnosis': diagnosis.text.trim(),
                    'note': note.text.trim(),
                    'items': lines.map((line) => line.toMap()).toList(),
                  });
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lưu đơn'),
              ),
            ],
          );
        },
      ),
    );

    diagnosis.dispose();
    note.dispose();
    for (final line in lines) {
      line.dispose();
    }
    if (payload == null) return;
    setState(() => busy = true);
    try {
      if (prescription == null) {
        await widget.service.createPrescription(
          widget.visit['id'].toString(),
          payload,
        );
      } else {
        await widget.service.updatePrescription(
          prescription['id'].toString(),
          payload,
        );
      }
      await load();
      showMessage('Đã lưu đơn thuốc');
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> transition(
    Map<String, dynamic> prescription,
    Future<Map<String, dynamic>> Function(String id) action,
    String message,
  ) async {
    setState(() => busy = true);
    try {
      await action(prescription['id'].toString());
      await load();
      showMessage(message);
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
              'Đơn thuốc theo lượt khám',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: busy ? null : () => openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Tạo đơn'),
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
        if (prescriptions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Chưa có đơn thuốc')),
          )
        else
          ...prescriptions.map(prescriptionCard),
      ],
    );
  }

  Widget prescriptionCard(Map<String, dynamic> prescription) {
    final status = prescription['status']?.toString() ?? '';
    final items = prescription['items'] as List? ?? const [];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        initiallyExpanded: prescriptions.length == 1,
        title: Text(
          prescription['prescriptionCode']?.toString() ?? '',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${prescriptionStatus(status)} • ${items.length} thuốc • ${money(prescription['totalAmount'])}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (prescription['diagnosis']?.toString().isNotEmpty == true)
                  Text('Chẩn đoán: ${prescription['diagnosis']}'),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowMinHeight: 40,
                    columns: const [
                      DataColumn(label: Text('Thuốc')),
                      DataColumn(label: Text('Liều dùng')),
                      DataColumn(label: Text('Tần suất')),
                      DataColumn(label: Text('Số ngày')),
                      DataColumn(label: Text('SL')),
                      DataColumn(label: Text('Đơn vị')),
                      DataColumn(label: Text('Cách dùng')),
                      DataColumn(label: Text('Thành tiền')),
                    ],
                    rows: items.map((value) {
                      final item = Map<String, dynamic>.from(value as Map);
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(item['medicineName']?.toString() ?? ''),
                          ),
                          DataCell(Text(item['dosage']?.toString() ?? '')),
                          DataCell(Text(item['frequency']?.toString() ?? '')),
                          DataCell(Text(item['duration']?.toString() ?? '')),
                          DataCell(Text(item['quantity']?.toString() ?? '')),
                          DataCell(Text(item['unit']?.toString() ?? '')),
                          DataCell(Text(item['instruction']?.toString() ?? '')),
                          DataCell(Text(money(item['amount']))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: status == 'DRAFT' && !busy
                          ? () => openEditor(prescription)
                          : null,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Sửa'),
                    ),
                    FilledButton.icon(
                      onPressed: status == 'DRAFT' && !busy
                          ? () => transition(
                              prescription,
                              widget.service.prescribePrescription,
                              'Đã gửi đơn chờ phát',
                            )
                          : null,
                      icon: const Icon(Icons.send_outlined),
                      label: const Text('Kê đơn'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          !['DISPENSED', 'CANCELLED'].contains(status) && !busy
                          ? () => transition(
                              prescription,
                              widget.service.cancelPrescription,
                              'Đã hủy đơn thuốc',
                            )
                          : null,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Hủy'),
                    ),
                    OutlinedButton.icon(
                      onPressed: status == 'CANCELLED'
                          ? null
                          : () => showMessage(
                              'Đơn thuốc ${prescription['prescriptionCode']} đã sẵn sàng để in',
                            ),
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('In đơn'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget textField(
    String label,
    TextEditingController controller, {
    bool number = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  String prescriptionStatus(String value) =>
      const {
        'DRAFT': 'Nháp',
        'PRESCRIBED': 'Đã kê',
        'WAITING_DISPENSE': 'Chờ phát',
        'DISPENSED': 'Đã phát',
        'CANCELLED': 'Đã hủy',
      }[value] ??
      value;

  String money(dynamic value) {
    final number = num.tryParse(value?.toString() ?? '') ?? 0;
    final digits = number.round().toString();
    return '${digits.replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (match) => '.')} đ';
  }
}

class _PrescriptionLine {
  String? medicineId;
  final dosage = TextEditingController();
  final frequency = TextEditingController();
  final duration = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final unit = TextEditingController();
  final instruction = TextEditingController();
  bool insuranceCovered = false;

  _PrescriptionLine();

  factory _PrescriptionLine.fromMap(Map<String, dynamic> value) {
    final line = _PrescriptionLine();
    line.medicineId = value['medicineId']?.toString();
    line.dosage.text = value['dosage']?.toString() ?? '';
    line.frequency.text = value['frequency']?.toString() ?? '';
    line.duration.text = value['duration']?.toString() ?? '';
    line.quantity.text = value['quantity']?.toString() ?? '1';
    line.unit.text = value['unit']?.toString() ?? '';
    line.instruction.text = value['instruction']?.toString() ?? '';
    line.insuranceCovered = value['insuranceCovered'] == true;
    return line;
  }

  Map<String, dynamic> toMap() => {
    'medicineId': medicineId,
    'dosage': dosage.text.trim(),
    'frequency': frequency.text.trim(),
    'duration': int.tryParse(duration.text.trim()),
    'quantity': double.tryParse(quantity.text.trim()) ?? 0,
    'unit': unit.text.trim(),
    'instruction': instruction.text.trim(),
    'insuranceCovered': insuranceCovered,
  };

  void dispose() {
    dosage.dispose();
    frequency.dispose();
    duration.dispose();
    quantity.dispose();
    unit.dispose();
    instruction.dispose();
  }
}
