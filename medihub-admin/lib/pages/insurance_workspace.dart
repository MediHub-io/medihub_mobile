import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';
import '../core/his_workflow_models.dart';

class InsuranceWorkspace extends StatefulWidget {
  const InsuranceWorkspace({super.key, required this.service});
  final AdminApiService service;

  @override
  State<InsuranceWorkspace> createState() => _InsuranceWorkspaceState();
}

class _InsuranceWorkspaceState extends State<InsuranceWorkspace> {
  final search = TextEditingController();
  List<InsuranceClaimDto> claims = [];
  InsuranceClaimDto? selected;
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
      final rows = await widget.service.loadInsuranceClaims(
        search: search.text,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        claims = rows;
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

  Future<void> createClaim() async {
    final visits = await widget.service.loadOutpatientVisits();
    final admissions = await widget.service.loadAdmissions(status: 'ALL');
    var sourceType = 'VISIT';
    String? sourceId;
    final insuranceNo = TextEditingController();
    final note = TextEditingController();
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo hồ sơ BHYT'),
          content: SizedBox(
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'VISIT', label: Text('Ngoại trú')),
                    ButtonSegment(value: 'ADMISSION', label: Text('Nội trú')),
                  ],
                  selected: {sourceType},
                  onSelectionChanged: (value) => setDialogState(() {
                    sourceType = value.first;
                    sourceId = null;
                  }),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: sourceId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Hồ sơ nguồn',
                    border: OutlineInputBorder(),
                  ),
                  items: (sourceType == 'VISIT' ? visits : admissions)
                      .map(
                        (item) => DropdownMenuItem(
                          value: item['id']?.toString(),
                          child: Text(
                            sourceType == 'VISIT'
                                ? '${item['visitCode']} - ${item['patientCode']} - ${item['patient']}'
                                : '${item['admissionCode']} - ${item['patientCode']} - ${item['patient']}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => sourceId = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: insuranceNo,
                  decoration: const InputDecoration(
                    labelText: 'Số thẻ BHYT',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
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
              onPressed: sourceId == null
                  ? null
                  : () => Navigator.pop(context, {
                      if (sourceType == 'VISIT') 'visitId': sourceId,
                      if (sourceType == 'ADMISSION') 'admissionId': sourceId,
                      'insuranceNo': insuranceNo.text.trim(),
                      'note': note.text.trim(),
                    }),
              child: const Text('Tạo hồ sơ'),
            ),
          ],
        ),
      ),
    );
    insuranceNo.dispose();
    note.dispose();
    if (data == null) return;
    final value = await widget.service.createInsuranceClaim(data);
    await load(selectId: value.id);
  }

  Future<void> editClaim() async {
    final item = selected;
    if (item == null || item.status != 'DRAFT') return;
    final insuranceNo = TextEditingController(text: item.insuranceNo);
    final note = TextEditingController(
      text: item.data['note']?.toString() ?? '',
    );
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sửa hồ sơ ${item.claimCode}'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: insuranceNo,
                decoration: const InputDecoration(labelText: 'Số thẻ BHYT'),
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
            onPressed: () => Navigator.pop(context, {
              'insuranceNo': insuranceNo.text.trim(),
              'note': note.text.trim(),
            }),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    insuranceNo.dispose();
    note.dispose();
    if (data == null) return;
    await widget.service.updateInsuranceClaim(item.id, data);
    await load(selectId: item.id);
  }

  Future<void> transition(String action) async {
    final item = selected;
    if (item == null) return;
    Map<String, dynamic> data = {};
    if (action == 'approve') {
      data = {'approvedAmount': item.coveredAmount};
    }
    if (action == 'reject') {
      final controller = TextEditingController();
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Từ chối hồ sơ BHYT'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Lý do'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Từ chối'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (reason == null || reason.isEmpty) return;
      data = {'reason': reason};
    }
    await widget.service.transitionInsuranceClaim(item.id, action, data);
    await load(selectId: item.id);
  }

  @override
  Widget build(BuildContext context) {
    final current = selected?.status;
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 340,
              child: TextField(
                controller: search,
                onSubmitted: (_) => load(),
                decoration: const InputDecoration(
                  hintText: 'Mã hồ sơ, mã BN, tên, số thẻ',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 6),
            DropdownButton<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                DropdownMenuItem(value: 'DRAFT', child: Text('Nháp')),
                DropdownMenuItem(value: 'SUBMITTED', child: Text('Đã gửi')),
                DropdownMenuItem(value: 'APPROVED', child: Text('Đã duyệt')),
                DropdownMenuItem(value: 'REJECTED', child: Text('Từ chối')),
                DropdownMenuItem(value: 'CANCELLED', child: Text('Hủy')),
              ],
              onChanged: (value) {
                setState(() => status = value!);
                load();
              },
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: createClaim,
              icon: const Icon(Icons.add),
              label: const Text('Tạo hồ sơ'),
            ),
            const SizedBox(width: 5),
            OutlinedButton(
              onPressed: current == 'DRAFT' ? editClaim : null,
              child: const Text('Sửa'),
            ),
            const SizedBox(width: 5),
            FilledButton.tonal(
              onPressed: current == 'DRAFT' ? () => transition('submit') : null,
              child: const Text('Gửi giám định'),
            ),
            const SizedBox(width: 5),
            FilledButton.tonal(
              onPressed: current == 'SUBMITTED'
                  ? () => transition('approve')
                  : null,
              child: const Text('Duyệt'),
            ),
            const SizedBox(width: 5),
            FilledButton.tonal(
              onPressed: current == 'SUBMITTED'
                  ? () => transition('reject')
                  : null,
              child: const Text('Từ chối'),
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
              flex: 58,
              child: _panel(
                'Danh sách hồ sơ BHYT',
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Mã hồ sơ')),
                      DataColumn(label: Text('Mã BN')),
                      DataColumn(label: Text('Người bệnh')),
                      DataColumn(label: Text('Số thẻ')),
                      DataColumn(label: Text('Tổng tiền')),
                      DataColumn(label: Text('BHYT')),
                      DataColumn(label: Text('Trạng thái')),
                    ],
                    rows: claims
                        .map(
                          (item) => DataRow(
                            selected: item.id == selected?.id,
                            onSelectChanged: (_) =>
                                setState(() => selected = item),
                            cells: [
                              DataCell(Text(item.claimCode)),
                              DataCell(Text(item.patientCode)),
                              DataCell(Text(item.patient)),
                              DataCell(Text(item.insuranceNo)),
                              DataCell(Text(_money(item.totalAmount))),
                              DataCell(Text(_money(item.coveredAmount))),
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
              flex: 42,
              child: _panel(
                'Chi tiết hồ sơ',
                selected == null
                    ? const SizedBox(
                        height: 260,
                        child: Center(child: Text('Chọn hồ sơ BHYT')),
                      )
                    : _detail(selected!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detail(InsuranceClaimDto item) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _line('Mã hồ sơ', item.claimCode),
      _line('Người bệnh', '${item.patientCode} - ${item.patient}'),
      _line('Số thẻ BHYT', item.insuranceNo),
      _line(
        item.admissionCode.isEmpty ? 'Lượt khám' : 'Nội trú',
        item.admissionCode.isEmpty ? item.visitCode : item.admissionCode,
      ),
      _line('Hóa đơn', item.data['invoiceCode']),
      _line('Tổng chi phí', _money(item.totalAmount)),
      _line('Đề nghị BHYT', _money(item.coveredAmount)),
      _line('BHYT duyệt', _money(item.approvedAmount)),
      _line('Người bệnh trả', _money(item.patientAmount)),
      _line('Trạng thái', item.status),
      _line('Lý do từ chối', item.data['rejectionReason']),
      _line('Ghi chú', item.data['note']),
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

  String _money(int value) =>
      '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ';

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
