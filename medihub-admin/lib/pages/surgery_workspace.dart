import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';
import '../core/admin_models.dart';
import '../core/surgery_print_helper.dart';
import '../core/surgery_models.dart';

class SurgeryWorkspace extends StatefulWidget {
  final AdminApiService service;

  const SurgeryWorkspace({super.key, required this.service});

  @override
  State<SurgeryWorkspace> createState() => _SurgeryWorkspaceState();
}

class _SurgeryWorkspaceState extends State<SurgeryWorkspace> {
  final keywordController = TextEditingController();
  final preDiagnosis = TextEditingController();
  final postDiagnosis = TextEditingController();
  final description = TextEditingController();
  final result = TextEditingController();
  final complication = TextEditingController();
  final note = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String? departmentId;
  String status = 'ALL';
  List<SurgeryCaseDto> cases = [];
  SurgeryCaseDetailDto? selected;
  List<AdminRecord> departments = [];
  List<AdminRecord> doctors = [];
  List<Map<String, dynamic>> catalogs = [];
  List<Map<String, dynamic>> supplies = [];
  List<Map<String, dynamic>> medicines = [];
  List<Map<String, dynamic>> visits = [];
  List<Map<String, dynamic>> admissions = [];
  List<_TeamLine> team = [];
  List<_ConsumableLine> consumables = [];
  List<Map<String, dynamic>> attachments = [];
  bool loading = true;
  bool busy = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadWorkspace();
  }

  @override
  void dispose() {
    keywordController.dispose();
    preDiagnosis.dispose();
    postDiagnosis.dispose();
    description.dispose();
    result.dispose();
    complication.dispose();
    note.dispose();
    clearLines();
    super.dispose();
  }

  void clearLines() {
    for (final line in team) {
      line.dispose();
    }
    for (final line in consumables) {
      line.dispose();
    }
    team = [];
    consumables = [];
  }

  Future<void> loadWorkspace({bool preserveSelection = true}) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final results = await Future.wait([
        widget.service.loadSurgeryCases(
          date: apiDate(selectedDate),
          departmentId: departmentId,
          status: status,
          keyword: keywordController.text.trim(),
        ),
        widget.service.lookup(AdminRoute.departments),
        widget.service.lookup(AdminRoute.doctors),
        widget.service.loadTechnicalServices(),
        widget.service.loadSupplies(),
        widget.service.loadMedicines(),
        widget.service.loadOutpatientVisits(),
        widget.service.loadAdmissions(status: 'ALL'),
      ]);
      final rows = results[0] as List<SurgeryCaseDto>;
      final selectedId = preserveSelection ? selected?.id : null;
      if (!mounted) return;
      setState(() {
        cases = rows;
        departments = results[1] as List<AdminRecord>;
        doctors = results[2] as List<AdminRecord>;
        catalogs = results[3] as List<Map<String, dynamic>>;
        supplies = results[4] as List<Map<String, dynamic>>;
        medicines = results[5] as List<Map<String, dynamic>>;
        visits = results[6] as List<Map<String, dynamic>>;
        admissions = results[7] as List<Map<String, dynamic>>;
      });
      final id = rows
          .where((item) => item.id == selectedId)
          .map((item) => item.id)
          .firstOrNull;
      if (id != null) {
        await selectCase(id);
      } else if (rows.isNotEmpty) {
        await selectCase(rows.first.id);
      } else {
        setState(() => selected = null);
        fillDetail();
      }
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> selectCase(String id) async {
    try {
      final detail = await widget.service.loadSurgeryCaseDetail(id);
      if (!mounted) return;
      setState(() => selected = detail);
      fillDetail();
    } catch (error) {
      showMessage(error.toString(), error: true);
    }
  }

  void fillDetail() {
    final data = selected?.data ?? const <String, dynamic>{};
    preDiagnosis.text = data['preDiagnosis']?.toString() ?? '';
    postDiagnosis.text = data['postDiagnosis']?.toString() ?? '';
    description.text = data['description']?.toString() ?? '';
    result.text = data['result']?.toString() ?? '';
    complication.text = data['complication']?.toString() ?? '';
    note.text = data['note']?.toString() ?? '';
    clearLines();
    team = selected?.teamMembers.map(_TeamLine.fromDto).toList() ?? [];
    consumables =
        selected?.consumables.map(_ConsumableLine.fromDto).toList() ?? [];
    if (team.isEmpty) team.add(_TeamLine());
    if (consumables.isEmpty) consumables.add(_ConsumableLine());
    attachments = (data['attachments'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    if (mounted) setState(() {});
  }

  bool get editable =>
      selected != null &&
      !['COMPLETED', 'CANCELLED'].contains(selected!.status);

  Future<void> createCase() async {
    String sourceType = 'VISIT';
    String? sourceId;
    String? catalogId;
    String? selectedDepartmentId;
    String? mainDoctorId;
    DateTime scheduledAt = DateTime.now().add(const Duration(hours: 1));
    final anesthesia = TextEditingController();
    final diagnosis = TextEditingController();
    final create = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Lên lịch phẫu thuật / thủ thuật'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
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
                    decoration: InputDecoration(
                      labelText: sourceType == 'VISIT'
                          ? 'Lượt khám'
                          : 'Hồ sơ nội trú',
                      border: const OutlineInputBorder(),
                    ),
                    items: (sourceType == 'VISIT' ? visits : admissions)
                        .map(
                          (item) => DropdownMenuItem(
                            value: item['id'].toString(),
                            child: Text(
                              sourceType == 'VISIT'
                                  ? '${item['visitCode']} - ${item['patient']}'
                                  : '${item['admissionCode']} - ${item['patient']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => sourceId = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: catalogId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Phẫu thuật / thủ thuật',
                      border: OutlineInputBorder(),
                    ),
                    items: catalogs
                        .map(
                          (item) => DropdownMenuItem(
                            value: item['id'].toString(),
                            child: Text(
                              '${item['name']} - ${money(item['price'])}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => catalogId = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedDepartmentId,
                          decoration: const InputDecoration(
                            labelText: 'Khoa',
                            border: OutlineInputBorder(),
                          ),
                          items: departments
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.data['name']?.toString() ?? '',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setDialogState(
                            () => selectedDepartmentId = value,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: mainDoctorId,
                          decoration: const InputDecoration(
                            labelText: 'Bác sĩ chính',
                            border: OutlineInputBorder(),
                          ),
                          items: doctors
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.data['fullName']?.toString() ?? '',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setDialogState(() => mainDoctorId = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final value = await showDatePicker(
                        context: context,
                        initialDate: scheduledAt,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (value == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(scheduledAt),
                      );
                      if (time == null) return;
                      setDialogState(() {
                        scheduledAt = DateTime(
                          value.year,
                          value.month,
                          value.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                    icon: const Icon(Icons.schedule),
                    label: Text(dateTime(scheduledAt)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: anesthesia,
                    decoration: const InputDecoration(
                      labelText: 'Phương pháp vô cảm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: diagnosis,
                    decoration: const InputDecoration(
                      labelText: 'Chẩn đoán trước PTTT',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed:
                  sourceId == null ||
                      catalogId == null ||
                      selectedDepartmentId == null ||
                      mainDoctorId == null
                  ? null
                  : () => Navigator.pop(dialogContext, {
                      if (sourceType == 'VISIT') 'visitId': sourceId,
                      if (sourceType == 'ADMISSION') 'admissionId': sourceId,
                      'procedureCatalogId': catalogId,
                      'departmentId': selectedDepartmentId,
                      'mainDoctorId': mainDoctorId,
                      'scheduledAt': scheduledAt.toIso8601String(),
                      'anesthesiaMethod': anesthesia.text.trim(),
                      'preDiagnosis': diagnosis.text.trim(),
                    }),
              child: const Text('Lên lịch'),
            ),
          ],
        ),
      ),
    );
    anesthesia.dispose();
    diagnosis.dispose();
    if (create == null) return;
    setState(() => busy = true);
    try {
      final value = await widget.service.createSurgeryCase(create);
      showMessage('Đã tạo ca ${value.surgeryCode}');
      await loadWorkspace(preserveSelection: false);
      await selectCase(value.id);
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> startCase() async {
    if (selected == null) return;
    await action(
      () => widget.service.startSurgeryCase(selected!.id),
      'Đã bắt đầu ca',
    );
  }

  Future<void> completeCase() async {
    if (selected == null) return;
    await action(
      () => widget.service.completeSurgeryCase(selected!.id, draftPayload()),
      'Đã hoàn thành ca và cập nhật viện phí',
    );
  }

  Map<String, dynamic> draftPayload() => {
    'preDiagnosis': preDiagnosis.text.trim(),
    'postDiagnosis': postDiagnosis.text.trim(),
    'description': description.text.trim(),
    'result': result.text.trim(),
    'complication': complication.text.trim(),
    'note': note.text.trim(),
    'teamMembers': team.map((item) => item.dto.toJson()).toList(),
    'consumables': consumables.map((item) => item.dto.toJson()).toList(),
    'attachments': attachments,
  };

  Future<void> cancelCase() async {
    if (selected == null) return;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy ca PTTT'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Lý do hủy',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Hủy ca'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null) return;
    await action(
      () => widget.service.cancelSurgeryCase(selected!.id, reason),
      'Đã hủy ca',
    );
  }

  Future<void> action(
    Future<SurgeryCaseDetailDto> Function() operation,
    String message,
  ) async {
    setState(() => busy = true);
    try {
      final value = await operation();
      setState(() => selected = value);
      fillDetail();
      showMessage(message);
      await loadWorkspace();
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> saveDraftSections() async {
    if (selected == null) return;
    setState(() => busy = true);
    try {
      final value = await widget.service.saveSurgeryDraft(
        selected!.id,
        draftPayload(),
      );
      if (!mounted) return;
      setState(() => selected = value);
      fillDetail();
      showMessage('Đã lưu bản nháp biên bản, kíp, vật tư và file đính kèm');
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> attachFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || file.bytes == null) return;
    setState(() => busy = true);
    try {
      final upload = await widget.service.uploadFile(
        fileName: file.name,
        bytes: file.bytes!,
      );
      final fileUrl =
          upload['fileUrl']?.toString() ?? upload['url']?.toString() ?? '';
      if (fileUrl.isEmpty) {
        throw StateError('API upload không trả về đường dẫn file');
      }
      attachments.add({
        'fileName': file.name,
        'fileUrl': fileUrl,
        'fileType': file.extension,
      });
      final value = await widget.service.saveSurgeryDraft(
        selected!.id,
        draftPayload(),
      );
      if (!mounted) return;
      setState(() => selected = value);
      fillDetail();
      showMessage('Đã tải lên và lưu đính kèm ${file.name}');
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> printReport() async {
    if (selected == null) return;
    final report = await widget.service.printSurgeryReport(selected!.id);
    if (!mounted) return;
    openSurgeryReport(
      report: report,
      organizationName: widget.service.organizationName,
    );
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
            if (constraints.maxWidth < 1150) {
              return Column(
                children: [caseList(), const SizedBox(height: 6), detail()],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 42, child: caseList()),
                const SizedBox(width: 6),
                Expanded(flex: 58, child: detail()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget toolbar() {
    final current = selected?.status;
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            toolButton('Lên lịch', Icons.add, true, createCase),
            toolButton(
              'Bắt đầu',
              Icons.play_circle_outline,
              ['SCHEDULED', 'PREPARING'].contains(current),
              startCase,
            ),
            toolButton(
              'Lưu kíp/vật tư',
              Icons.save_outlined,
              editable,
              saveDraftSections,
            ),
            toolButton(
              'Hoàn thành',
              Icons.task_alt,
              current == 'IN_PROGRESS',
              completeCase,
            ),
            toolButton(
              'Hủy',
              Icons.cancel_outlined,
              ['SCHEDULED', 'PREPARING', 'IN_PROGRESS'].contains(current),
              cancelCase,
            ),
            toolButton(
              'In biên bản',
              Icons.print_outlined,
              current == 'COMPLETED',
              printReport,
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
        OutlinedButton.icon(
          onPressed: pickDate,
          icon: const Icon(Icons.calendar_month),
          label: Text(displayDate(selectedDate)),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: departmentId,
            decoration: const InputDecoration(
              labelText: 'Khoa',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Tất cả')),
              ...departments.map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(item.data['name']?.toString() ?? ''),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() => departmentId = value);
              loadWorkspace(preserveSelection: false);
            },
          ),
        ),
        SizedBox(
          width: 175,
          child: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
              DropdownMenuItem(value: 'SCHEDULED', child: Text('Đã lên lịch')),
              DropdownMenuItem(value: 'PREPARING', child: Text('Chuẩn bị')),
              DropdownMenuItem(
                value: 'IN_PROGRESS',
                child: Text('Đang thực hiện'),
              ),
              DropdownMenuItem(value: 'COMPLETED', child: Text('Hoàn thành')),
              DropdownMenuItem(value: 'CANCELLED', child: Text('Đã hủy')),
            ],
            onChanged: (value) {
              setState(() => status = value ?? 'ALL');
              loadWorkspace(preserveSelection: false);
            },
          ),
        ),
        SizedBox(
          width: 310,
          child: TextField(
            controller: keywordController,
            onSubmitted: (_) => loadWorkspace(preserveSelection: false),
            decoration: InputDecoration(
              hintText: 'Bệnh nhân / mã ca / mã hồ sơ',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => loadWorkspace(preserveSelection: false),
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
      ],
    ),
  );

  Widget caseList() => panel(
    'Danh sách ca PTTT',
    cases.isEmpty
        ? const SizedBox(
            height: 220,
            child: Center(child: Text('Không có ca phù hợp')),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 46,
              columns: const [
                DataColumn(label: Text('Mã ca')),
                DataColumn(label: Text('Bệnh nhân')),
                DataColumn(label: Text('Tên PTTT')),
                DataColumn(label: Text('Khoa')),
                DataColumn(label: Text('Bác sĩ chính')),
                DataColumn(label: Text('Giờ dự kiến')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: cases.map((item) {
                final data = item.data;
                return DataRow(
                  selected: item.id == selected?.id,
                  onSelectChanged: (_) => selectCase(item.id),
                  cells: [
                    DataCell(Text(item.surgeryCode)),
                    DataCell(Text(item.patient)),
                    DataCell(SizedBox(width: 170, child: Text(item.title))),
                    DataCell(Text(data['department']?.toString() ?? '')),
                    DataCell(Text(data['mainDoctor']?.toString() ?? '')),
                    DataCell(Text(dateTime(data['scheduledAt']))),
                    DataCell(statusPill(item.status)),
                  ],
                );
              }).toList(),
            ),
          ),
  );

  Widget detail() {
    if (selected == null) {
      return panel(
        'Workspace / Biên bản PTTT',
        const SizedBox(
          height: 320,
          child: Center(child: Text('Chọn ca để mở biên bản')),
        ),
      );
    }
    final data = selected!.data;
    return panel(
      'Workspace / Biên bản PTTT',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          section(
            'A. Thông tin bệnh nhân',
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                info('Mã BN', data['patientCode']),
                info('Họ tên', data['patient']),
                info('Ngày sinh', dateOnly(data['patientDob'])),
                info('Giới tính', data['patientGender']),
                info(
                  data['admissionId']?.toString().isNotEmpty == true
                      ? 'Admission'
                      : 'Visit',
                  data['admissionCode']?.toString().isNotEmpty == true
                      ? data['admissionCode']
                      : data['visitCode'],
                ),
                info('Chẩn đoán', data['preDiagnosis']),
              ],
            ),
          ),
          section(
            'B. Thông tin PTTT',
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                info('Tên PTTT', data['title']),
                info('Khoa', data['department']),
                info('Bác sĩ chính', data['mainDoctor']),
                info('Giờ dự kiến', dateTime(data['scheduledAt'])),
                info('Phương pháp vô cảm', data['anesthesiaMethod']),
                info('Trạng thái', statusText(selected!.status)),
                info('Chi phí đã lên bảng kê', money(data['billingTotal'])),
              ],
            ),
          ),
          section('C. Kíp PTTT', teamEditor()),
          section(
            'D. Biên bản PTTT',
            Column(
              children: [
                field('Chẩn đoán trước PTTT', preDiagnosis, lines: 2),
                field('Chẩn đoán sau PTTT', postDiagnosis, lines: 2),
                field('Mô tả quá trình thực hiện', description, lines: 5),
                field('Kết quả', result, lines: 3),
                field('Biến chứng', complication, lines: 2),
                field('Ghi chú', note, lines: 2),
              ],
            ),
          ),
          section('E. Vật tư / thuốc / dịch truyền', consumableEditor()),
          section(
            'F. File đính kèm',
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (attachments.isEmpty) const Text('Chưa có file đính kèm'),
                ...attachments.map(
                  (item) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.attach_file),
                    title: Text(item['fileName']?.toString() ?? ''),
                    subtitle: Text(item['fileUrl']?.toString() ?? ''),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: editable && !busy ? attachFile : null,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Đính kèm PDF / hình ảnh'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget teamEditor() => Column(
    children: [
      ...team.asMap().entries.map((entry) {
        final line = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: line.role,
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: teamRoles
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(roleText(role)),
                        ),
                      )
                      .toList(),
                  onChanged: editable
                      ? (value) => setState(() => line.role = value!)
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: doctors.any((item) => item.id == line.staffId)
                      ? line.staffId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Nhân sự',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: doctors
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.data['fullName']?.toString() ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: editable
                      ? (value) => setState(() {
                          line.staffId = value;
                          line.staffName = doctors
                              .where((item) => item.id == value)
                              .map(
                                (item) =>
                                    item.data['fullName']?.toString() ?? '',
                              )
                              .firstOrNull;
                        })
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: field('Ghi chú', line.note)),
              IconButton(
                onPressed: editable && team.length > 1
                    ? () {
                        line.dispose();
                        setState(() => team.removeAt(entry.key));
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        );
      }),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: editable
              ? () => setState(() => team.add(_TeamLine()))
              : null,
          icon: const Icon(Icons.add),
          label: const Text('Thêm thành viên'),
        ),
      ),
    ],
  );

  Widget consumableEditor() => Column(
    children: [
      ...consumables.asMap().entries.map((entry) {
        final line = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: line.itemType,
                  decoration: const InputDecoration(
                    labelText: 'Loại',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: consumableTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: editable
                      ? (value) => setState(() => line.itemType = value!)
                      : null,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(flex: 2, child: field('Tên', line.itemName)),
              const SizedBox(width: 5),
              Expanded(child: field('SL', line.quantity, number: true)),
              const SizedBox(width: 5),
              Expanded(child: field('Đơn vị', line.unit)),
              const SizedBox(width: 5),
              Expanded(child: field('Đơn giá', line.unitPrice, number: true)),
              const SizedBox(width: 5),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Thành tiền',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(money(line.total)),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(child: field('Ghi chú', line.note)),
              IconButton(
                onPressed: editable && consumables.length > 1
                    ? () {
                        line.dispose();
                        setState(() => consumables.removeAt(entry.key));
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        );
      }),
      Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: editable
                  ? () => setState(() => consumables.add(_ConsumableLine()))
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Thêm dòng'),
            ),
            PopupMenuButton<Map<String, dynamic>>(
              enabled: editable,
              onSelected: (item) => setState(() {
                consumables.add(_ConsumableLine.fromCatalog(item));
              }),
              itemBuilder: (_) => [...medicines, ...supplies]
                  .map(
                    (item) => PopupMenuItem(
                      value: item,
                      child: Text('${item['name']} - ${money(item['price'])}'),
                    ),
                  )
                  .toList(),
              child: const Chip(
                avatar: Icon(Icons.search, size: 16),
                label: Text('Chọn từ danh mục'),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget field(
    String label,
    TextEditingController controller, {
    int lines = 1,
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: TextField(
      controller: controller,
      enabled: editable,
      minLines: lines,
      maxLines: lines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  Widget section(String title, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFCBD5E1)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        child,
      ],
    ),
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
      color: value == 'COMPLETED'
          ? Colors.green.shade100
          : value == 'CANCELLED'
          ? Colors.red.shade100
          : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      statusText(value),
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );

  Future<void> pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value == null) return;
    setState(() => selectedDate = value);
    loadWorkspace(preserveSelection: false);
  }

  static const teamRoles = [
    'MAIN_SURGEON',
    'ANESTHESIOLOGIST',
    'ASSISTANT_SURGEON',
    'SCRUB_NURSE',
    'CIRCULATING_NURSE',
    'TECHNICIAN',
    'OTHER',
  ];

  static const consumableTypes = [
    'MEDICINE',
    'MATERIAL',
    'SUPPLY',
    'IMPLANT',
    'FLUID',
    'OTHER',
  ];

  static String roleText(String value) =>
      const {
        'MAIN_SURGEON': 'Bác sĩ chính',
        'ANESTHESIOLOGIST': 'Bác sĩ gây mê',
        'ASSISTANT_SURGEON': 'Phụ mổ',
        'SCRUB_NURSE': 'Điều dưỡng dụng cụ',
        'CIRCULATING_NURSE': 'Điều dưỡng vòng ngoài',
        'TECHNICIAN': 'Kỹ thuật viên',
        'OTHER': 'Khác',
      }[value] ??
      value;

  String statusText(String value) =>
      const {
        'SCHEDULED': 'Đã lên lịch',
        'PREPARING': 'Đang chuẩn bị',
        'IN_PROGRESS': 'Đang thực hiện',
        'COMPLETED': 'Hoàn thành',
        'CANCELLED': 'Đã hủy',
      }[value] ??
      value;

  String apiDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String dateOnly(dynamic value) {
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    return date == null ? '' : displayDate(date.toLocal());
  }

  static String dateTime(dynamic value) {
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static String money(dynamic value) {
    final number = num.tryParse('${value ?? 0}')?.round() ?? 0;
    return '${number.toString().replaceAllMapped(RegExp(r'(?=(\d{3})+(?!\d))'), (match) => '.')} đ';
  }
}

class _TeamLine {
  String role = 'OTHER';
  String? staffId;
  String? staffName;
  final note = TextEditingController();

  _TeamLine();

  factory _TeamLine.fromDto(SurgeryTeamMemberDto dto) {
    final line = _TeamLine();
    line.role = dto.role;
    line.staffId = dto.staffId;
    line.staffName = dto.staffName;
    line.note.text = dto.note;
    return line;
  }

  SurgeryTeamMemberDto get dto => SurgeryTeamMemberDto(
    staffId: staffId ?? '',
    staffName: staffName ?? '',
    role: role,
    note: note.text.trim(),
  );

  void dispose() => note.dispose();
}

class _ConsumableLine {
  String itemType = 'OTHER';
  String? itemId;
  final itemName = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final unit = TextEditingController();
  final unitPrice = TextEditingController();
  final note = TextEditingController();

  _ConsumableLine();

  factory _ConsumableLine.fromDto(SurgeryConsumableDto dto) {
    final line = _ConsumableLine();
    line.itemType = dto.itemType;
    line.itemId = dto.itemId;
    line.itemName.text = dto.itemName;
    line.quantity.text = '${dto.quantity}';
    line.unit.text = dto.unit;
    line.unitPrice.text = dto.unitPrice?.toString() ?? '';
    line.note.text = dto.note;
    return line;
  }

  factory _ConsumableLine.fromCatalog(Map<String, dynamic> item) {
    final line = _ConsumableLine();
    line.itemId = item['id']?.toString();
    line.itemType = item['type'] == 'MEDICINE' ? 'MEDICINE' : 'SUPPLY';
    line.itemName.text = item['name']?.toString() ?? '';
    line.unit.text = item['unit']?.toString() ?? '';
    line.unitPrice.text = item['price']?.toString() ?? '';
    return line;
  }

  int get total {
    final qty = double.tryParse(quantity.text.trim()) ?? 0;
    final price = int.tryParse(unitPrice.text.trim()) ?? 0;
    return (qty * price).round();
  }

  SurgeryConsumableDto get dto => SurgeryConsumableDto(
    itemId: itemId,
    itemType: itemType,
    itemName: itemName.text.trim(),
    quantity: double.tryParse(quantity.text.trim()) ?? 1,
    unit: unit.text.trim(),
    unitPrice: int.tryParse(unitPrice.text.trim()),
    totalPrice: total,
    note: note.text.trim(),
  );

  void dispose() {
    itemName.dispose();
    quantity.dispose();
    unit.dispose();
    unitPrice.dispose();
    note.dispose();
  }
}
