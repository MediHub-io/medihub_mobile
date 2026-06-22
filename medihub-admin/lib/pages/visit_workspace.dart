import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';
import '../core/admin_models.dart';
import '../core/his_workflow_models.dart';

class VisitWorkspace extends StatefulWidget {
  const VisitWorkspace({super.key, required this.service});
  final AdminApiService service;

  @override
  State<VisitWorkspace> createState() => _VisitWorkspaceState();
}

class _VisitWorkspaceState extends State<VisitWorkspace> {
  final search = TextEditingController();
  List<VisitDto> visits = [];
  VisitDto? selected;
  String status = 'ALL';
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load({String? selectId}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final rows = await widget.service.loadVisitWorkspace(
        search: search.text,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        visits = rows;
        selected = rows
            .where((item) => item.id == (selectId ?? selected?.id))
            .firstOrNull;
        selected ??= rows.firstOrNull;
      });
    } catch (value) {
      if (mounted) setState(() => error = value.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> createOrEdit([VisitDto? visit]) async {
    final departments = await widget.service.lookup(AdminRoute.departments);
    final doctors = await widget.service.lookup(AdminRoute.doctors);
    final patients = visit == null
        ? await widget.service.lookup(AdminRoute.patients)
        : const <AdminRecord>[];
    final reason = TextEditingController(
      text: visit?.data['reason']?.toString() ?? '',
    );
    final note = TextEditingController(
      text: visit?.data['note']?.toString() ?? '',
    );
    var departmentId = visit?.data['departmentId']?.toString();
    var doctorId = visit?.data['doctorId']?.toString();
    String? patientId = visit?.patientId;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(visit == null ? 'Tạo lượt khám' : 'Sửa lượt khám'),
          content: SizedBox(
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (visit == null)
                  DropdownButtonFormField<String>(
                    initialValue: patientId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Người bệnh'),
                    items: patients
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              '${item.data['patientCode'] ?? ''} - ${item.data['fullName'] ?? ''}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => patientId = value),
                  ),
                DropdownButtonFormField<String>(
                  initialValue: departmentId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Khoa'),
                  items: departments
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.data['name']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => departmentId = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: doctorId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Bác sĩ'),
                  items: doctors
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.data['fullName']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => doctorId = value),
                ),
                TextField(
                  controller: reason,
                  decoration: const InputDecoration(labelText: 'Lý do khám'),
                ),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Ghi chú'),
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
              onPressed:
                  departmentId == null || (visit == null && patientId == null)
                  ? null
                  : () => Navigator.pop(context, {
                      if (visit == null) 'patientId': patientId,
                      'departmentId': departmentId,
                      'doctorId': doctorId,
                      'reason': reason.text.trim(),
                      'note': note.text.trim(),
                      if (visit == null) 'visitType': 'OUTPATIENT',
                    }),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    reason.dispose();
    note.dispose();
    if (result == null) return;
    if (visit == null) {
      final created = await widget.service.createVisit(result);
      await load(selectId: created['id']?.toString());
    } else {
      await widget.service.update(AdminRoute.visits, visit.id, result);
      await load(selectId: visit.id);
    }
  }

  Future<void> transition(String action) async {
    final item = selected;
    if (item == null) return;
    switch (action) {
      case 'check-in':
        await widget.service.checkInVisit(item.id);
      case 'start':
        await widget.service.startVisitExam(item.id);
      case 'complete':
        await widget.service.completeVisit(item.id);
      case 'cancel':
        await widget.service.cancelVisit(item.id);
    }
    await load(selectId: item.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 340,
              child: TextField(
                controller: search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Mã lượt, mã BN, tên, SĐT',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => load(),
              ),
            ),
            const SizedBox(width: 6),
            DropdownButton<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                DropdownMenuItem(
                  value: 'WAITING_RECEPTION',
                  child: Text('Chờ tiếp nhận'),
                ),
                DropdownMenuItem(
                  value: 'WAITING_EXAM',
                  child: Text('Chờ khám'),
                ),
                DropdownMenuItem(value: 'IN_EXAM', child: Text('Đang khám')),
                DropdownMenuItem(
                  value: 'WAITING_PAYMENT',
                  child: Text('Chờ thanh toán'),
                ),
                DropdownMenuItem(value: 'COMPLETED', child: Text('Hoàn tất')),
              ],
              onChanged: (value) {
                setState(() => status = value!);
                load();
              },
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => createOrEdit(),
              icon: const Icon(Icons.add),
              label: const Text('Tạo lượt khám'),
            ),
            const SizedBox(width: 5),
            OutlinedButton.icon(
              onPressed: selected == null ? null : () => createOrEdit(selected),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sửa'),
            ),
            const SizedBox(width: 5),
            FilledButton.tonal(
              onPressed: selected?.status == 'WAITING_RECEPTION'
                  ? () => transition('check-in')
                  : null,
              child: const Text('Tiếp nhận'),
            ),
            const SizedBox(width: 5),
            FilledButton.tonal(
              onPressed: selected?.status == 'WAITING_EXAM'
                  ? () => transition('start')
                  : null,
              child: const Text('Bắt đầu khám'),
            ),
            const SizedBox(width: 5),
            FilledButton.tonal(
              onPressed: selected?.status == 'IN_EXAM'
                  ? () => transition('complete')
                  : null,
              child: const Text('Hoàn tất'),
            ),
          ],
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 55,
              child: _panel(
                'Danh sách lượt khám',
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Mã lượt')),
                      DataColumn(label: Text('Mã BN')),
                      DataColumn(label: Text('Bệnh nhân')),
                      DataColumn(label: Text('Khoa')),
                      DataColumn(label: Text('Bác sĩ')),
                      DataColumn(label: Text('Trạng thái')),
                    ],
                    rows: visits
                        .map(
                          (item) => DataRow(
                            selected: item.id == selected?.id,
                            onSelectChanged: (_) =>
                                setState(() => selected = item),
                            cells: [
                              DataCell(Text(item.visitCode)),
                              DataCell(Text(item.patientCode)),
                              DataCell(Text(item.patient)),
                              DataCell(Text(item.department)),
                              DataCell(Text(item.doctor)),
                              DataCell(Text(item.status)),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 45,
              child: _panel(
                'Chi tiết lượt khám',
                selected == null
                    ? const SizedBox(
                        height: 260,
                        child: Center(child: Text('Chọn lượt khám')),
                      )
                    : _detail(selected!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detail(VisitDto item) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _line('Mã lượt khám', item.visitCode),
      _line('Người bệnh', '${item.patientCode} - ${item.patient}'),
      _line('Khoa', item.department),
      _line('Bác sĩ', item.doctor),
      _line('Loại lượt', item.data['visitType']),
      _line('Lý do khám', item.data['reason']),
      _line('BHYT', item.data['insuranceNumber']),
      _line('Tiếp nhận', item.data['receptionTime']),
      _line('Trạng thái', item.status),
    ],
  );

  Widget _line(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: value?.toString() ?? ''),
        ],
      ),
    ),
  );

  Widget _panel(String title, Widget child) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFCBD5E1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFFE2E8F0),
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Padding(padding: const EdgeInsets.all(8), child: child),
      ],
    ),
  );
}
