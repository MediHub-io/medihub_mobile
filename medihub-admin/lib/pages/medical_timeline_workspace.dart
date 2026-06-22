import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';
import '../core/his_workflow_models.dart';

class MedicalTimelineWorkspace extends StatefulWidget {
  const MedicalTimelineWorkspace({super.key, required this.service});
  final AdminApiService service;

  @override
  State<MedicalTimelineWorkspace> createState() =>
      _MedicalTimelineWorkspaceState();
}

class _MedicalTimelineWorkspaceState extends State<MedicalTimelineWorkspace> {
  final search = TextEditingController();
  List<Map<String, dynamic>> visits = [];
  List<MedicalTimelineEventDto> events = [];
  Map<String, dynamic>? selectedVisit;
  String module = 'ALL';
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    searchVisits();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> searchVisits() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final visitDtos = await widget.service.loadVisitWorkspace(
        search: search.text,
        visitType: 'OUTPATIENT',
      );
      final rows = visitDtos
          .map((item) => {'id': item.id, ...item.data})
          .toList();
      if (!mounted) return;
      setState(() {
        visits = rows;
        selectedVisit ??= rows.firstOrNull;
      });
      await loadTimeline();
    } catch (value) {
      if (mounted) setState(() => error = value.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadTimeline() async {
    final visit = selectedVisit;
    if (visit == null) {
      setState(() => events = []);
      return;
    }
    final rows = await widget.service.loadMedicalTimeline(
      visitId: visit['id']?.toString(),
      module: module,
    );
    if (mounted) setState(() => events = rows);
  }

  Future<void> createEvent() async {
    final visit = selectedVisit;
    if (visit == null) return;
    var selectedModule = module == 'ALL' ? 'CLINICAL' : module;
    final eventType = TextEditingController();
    final title = TextEditingController();
    final description = TextEditingController();
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm diễn biến y khoa'),
          content: SizedBox(
            width: 580,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedModule,
                  decoration: const InputDecoration(labelText: 'Phân hệ'),
                  items: _modules
                      .where((item) => item != 'ALL')
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedModule = value!),
                ),
                TextField(
                  controller: eventType,
                  decoration: const InputDecoration(labelText: 'Loại sự kiện'),
                ),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Tiêu đề'),
                ),
                TextField(
                  controller: description,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Nội dung'),
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
              onPressed: () {
                if (eventType.text.trim().isEmpty ||
                    title.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, {
                  'patientId': visit['patientId'],
                  'visitId': visit['id'],
                  'module': selectedModule,
                  'eventType': eventType.text.trim(),
                  'title': title.text.trim(),
                  'description': description.text.trim(),
                  'actorName': widget.service.adminPhone,
                });
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    eventType.dispose();
    title.dispose();
    description.dispose();
    if (data == null) return;
    await widget.service.createMedicalTimelineEvent(data);
    await loadTimeline();
  }

  static const _modules = [
    'ALL',
    'RECEPTION',
    'VISIT',
    'DOCTOR',
    'LAB',
    'IMAGING',
    'PHARMACY',
    'BILLING',
    'ADMISSION',
    'SURGERY',
    'INSURANCE',
    'CLINICAL',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: search,
                onSubmitted: (_) => searchVisits(),
                decoration: const InputDecoration(
                  hintText: 'Tìm mã lượt, mã BN, tên, SĐT',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 6),
            DropdownButton<String>(
              value: module,
              items: _modules
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item == 'ALL' ? 'Tất cả phân hệ' : item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => module = value!);
                loadTimeline();
              },
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: selectedVisit == null ? null : createEvent,
              icon: const Icon(Icons.add),
              label: const Text('Thêm diễn biến'),
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
            SizedBox(
              width: 420,
              child: _panel(
                'Lượt khám / người bệnh',
                Column(
                  children: visits
                      .map(
                        (item) => ListTile(
                          dense: true,
                          selected: item['id'] == selectedVisit?['id'],
                          title: Text(
                            '${item['visitCode']} - ${item['patient']}',
                          ),
                          subtitle: Text(
                            '${item['patientCode']} · ${item['department']} · ${item['status']}',
                          ),
                          onTap: () {
                            setState(() => selectedVisit = item);
                            loadTimeline();
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _panel(
                'Timeline y khoa',
                events.isEmpty
                    ? const SizedBox(
                        height: 300,
                        child: Center(child: Text('Chưa có diễn biến')),
                      )
                    : Column(children: events.map(_eventTile).toList()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _eventTile(MedicalTimelineEventDto event) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            _dateTime(event.occurredAt),
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ),
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 4, right: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF005AA8),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                '${event.module} · ${event.eventType} · ${event.status}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF005AA8),
                ),
              ),
              if (event.description.isNotEmpty) Text(event.description),
            ],
          ),
        ),
      ],
    ),
  );

  String _dateTime(DateTime? value) {
    if (value == null) return '';
    final date = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

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
