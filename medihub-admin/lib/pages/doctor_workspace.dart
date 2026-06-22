import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';
import '../core/admin_models.dart';
import 'doctor_billing_tab.dart';
import 'doctor_prescription_tab.dart';

class DoctorWorkspace extends StatefulWidget {
  final AdminApiService service;
  final ValueChanged<AdminRoute>? onRouteChanged;

  const DoctorWorkspace({
    super.key,
    required this.service,
    this.onRouteChanged,
  });

  @override
  State<DoctorWorkspace> createState() => _DoctorWorkspaceState();
}

class _DoctorWorkspaceState extends State<DoctorWorkspace> {
  static const tabs = [
    'Hành chính',
    'Sinh hiệu',
    'Bệnh án',
    'Chỉ định',
    'Xét nghiệm',
    'CĐHA',
    'Thuốc',
    'Viện phí',
    'Lịch sử',
  ];

  final controllers = <String, TextEditingController>{
    for (final key in [
      'chiefComplaint',
      'pathologicalProcess',
      'personalHistory',
      'familyHistory',
      'allergies',
      'generalExam',
      'specializedExam',
      'preliminaryDiagnosis',
      'diagnosisCode',
      'diagnosisText',
      'secondaryDiagnosis',
      'treatmentPlan',
      'instructions',
      'conclusion',
    ])
      key: TextEditingController(),
  };

  List<Map<String, dynamic>> visits = [];
  List<Map<String, dynamic>> encounters = [];
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> labResults = [];
  List<Map<String, dynamic>> imagingResults = [];
  List<AdminRecord> departments = [];
  List<AdminRecord> rooms = [];
  List<AdminRecord> doctors = [];
  Map<String, dynamic>? selectedVisit;
  Map<String, dynamic>? encounter;

  DateTime selectedDate = DateTime.now();
  String status = 'WAITING_EXAM';
  String? departmentId;
  String? roomId;
  String? doctorId;
  String activeTab = 'Bệnh án';
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
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> loadWorkspace({bool preserveSelection = true}) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final results = await Future.wait([
        widget.service.loadOutpatientVisits(
          status: status == 'WAITING_CLS' ? 'IN_EXAM' : status,
          date: apiDate(selectedDate),
          departmentId: departmentId,
          roomId: roomId,
          doctorId: doctorId,
        ),
        widget.service.lookup(AdminRoute.departments),
        widget.service.lookup(AdminRoute.rooms),
        widget.service.lookup(AdminRoute.doctors),
      ]);
      final rows = results[0] as List<Map<String, dynamic>>;
      if (!mounted) return;
      final selectedId = preserveSelection && selectedVisit != null
          ? selectedVisit!['id']
          : null;
      setState(() {
        visits = rows;
        departments = results[1] as List<AdminRecord>;
        rooms = results[2] as List<AdminRecord>;
        doctors = results[3] as List<AdminRecord>;
        selectedVisit = rows.isEmpty
            ? null
            : rows.firstWhere(
                (item) => item['id'] == selectedId,
                orElse: () => rows.first,
              );
      });
      await loadSelectedVisit();
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> loadSelectedVisit() async {
    final visit = selectedVisit;
    if (visit == null) {
      setState(() {
        encounters = [];
        encounter = null;
        orders = [];
        labResults = [];
        imagingResults = [];
      });
      clearEncounterForm();
      return;
    }
    try {
      final results = await Future.wait([
        widget.service.loadVisitEncounters(visit['id'].toString()),
        widget.service.loadVisitOrders(visit['id'].toString()),
        widget.service.loadLabResults(visitId: visit['id'].toString()),
        widget.service.loadImagingResults(visitId: visit['id'].toString()),
      ]);
      if (!mounted) return;
      setState(() {
        encounters = results[0];
        encounter = encounters.isEmpty ? null : encounters.first;
        orders = results[1];
        labResults = results[2];
        imagingResults = results[3];
      });
      fillEncounterForm();
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    }
  }

  void fillEncounterForm() {
    final data = encounter ?? const <String, dynamic>{};
    final visit = selectedVisit ?? const <String, dynamic>{};
    for (final entry in controllers.entries) {
      entry.value.text =
          data[entry.key]?.toString() ??
          (entry.key == 'chiefComplaint'
              ? visit['reason']?.toString() ?? ''
              : '');
    }
  }

  void clearEncounterForm() {
    for (final controller in controllers.values) {
      controller.clear();
    }
  }

  Map<String, dynamic> encounterPayload() => {
    for (final entry in controllers.entries) entry.key: entry.value.text.trim(),
  };

  Future<void> selectVisit(Map<String, dynamic> visit) async {
    setState(() {
      selectedVisit = visit;
      encounter = null;
      encounters = [];
      orders = [];
      activeTab = 'Bệnh án';
    });
    clearEncounterForm();
    await loadSelectedVisit();
  }

  Future<void> startExam() async {
    final visit = selectedVisit;
    if (visit == null) return showMessage('Vui lòng chọn bệnh nhân');
    setState(() => busy = true);
    try {
      await widget.service.startVisitExam(visit['id'].toString());
      await loadWorkspace();
      showMessage('Đã bắt đầu khám và mở bệnh án');
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<Map<String, dynamic>?> ensureEncounter() async {
    if (encounter != null) return encounter;
    final visit = selectedVisit;
    if (visit == null) return null;
    if (visit['status'] != 'IN_EXAM') {
      showMessage('Cần bấm Bắt đầu khám trước khi lưu bệnh án', error: true);
      return null;
    }
    final created = await widget.service.createEncounter(
      visit['id'].toString(),
      encounterPayload(),
    );
    if (mounted) setState(() => encounter = created);
    return created;
  }

  Future<void> saveMedicalRecord() async {
    setState(() => busy = true);
    try {
      final current = await ensureEncounter();
      if (current == null) return;
      final saved = await widget.service.saveEncounter(
        current['id'].toString(),
        encounterPayload(),
      );
      if (mounted) setState(() => encounter = saved);
      showMessage('Đã lưu bệnh án');
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> finishExam() async {
    setState(() => busy = true);
    try {
      final current = await ensureEncounter();
      if (current == null) return;
      encounter = await widget.service.completeEncounter(
        current['id'].toString(),
        data: encounterPayload(),
      );
      final visit = await widget.service.completeVisit(
        selectedVisit!['id'].toString(),
      );
      await loadWorkspace(preserveSelection: false);
      showMessage(
        visit['status'] == 'WAITING_PAYMENT'
            ? 'Đã hoàn tất bệnh án, lượt khám chuyển chờ thanh toán'
            : 'Đã hoàn tất khám',
      );
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> admitSelectedVisit() async {
    final visit = selectedVisit;
    if (visit == null) return;
    final diagnosis =
        controllers['diagnosisText']?.text.trim() ??
        encounter?['diagnosisText']?.toString() ??
        '';
    setState(() => busy = true);
    try {
      await widget.service.admitVisit(visit['id'].toString(), {
        'encounterId': encounter?['id'],
        'departmentId': visit['departmentId'],
        'doctorId': visit['doctorId'],
        'admissionReason': visit['reason'],
        'diagnosis': diagnosis,
      });
      showMessage('Đã tạo hồ sơ nhập viện');
      widget.onRouteChanged?.call(AdminRoute.inpatient);
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void nextPatient() {
    if (visits.isEmpty) return;
    final currentId = selectedVisit?['id'];
    final index = visits.indexWhere((item) => item['id'] == currentId);
    final next = visits[(index + 1).clamp(0, visits.length - 1)];
    selectVisit(next);
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
            final stacked = constraints.maxWidth < 1100;
            if (stacked) {
              return Column(
                children: [
                  visitList(),
                  const SizedBox(height: 6),
                  clinicalWorkspace(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 42, child: visitList()),
                const SizedBox(width: 6),
                Expanded(flex: 58, child: clinicalWorkspace()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget toolbar() {
    final hasVisit = selectedVisit != null;
    final canStart = [
      'WAITING_EXAM',
      'RECEIVED',
    ].contains(selectedVisit?['status']);
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            toolButton('Gọi khám', Icons.campaign_outlined, hasVisit, () {
              showMessage(
                'Mời bệnh nhân ${selectedVisit?['patient'] ?? ''} vào phòng khám',
              );
            }),
            toolButton(
              'Bắt đầu khám',
              Icons.play_circle_outline,
              canStart,
              startExam,
            ),
            toolButton(
              'Lưu bệnh án',
              Icons.save_outlined,
              hasVisit,
              saveMedicalRecord,
            ),
            toolButton(
              'Chỉ định',
              Icons.medical_services_outlined,
              hasVisit,
              () {
                setState(() => activeTab = 'Chỉ định');
              },
            ),
            toolButton('Kê đơn', Icons.medication_outlined, hasVisit, () {
              setState(() => activeTab = 'Thuốc');
            }),
            toolButton('In phiếu khám', Icons.print_outlined, hasVisit, () {
              showMessage('Phiếu khám đã sẵn sàng để in từ tab Bệnh án');
            }),
            toolButton('Hoàn tất khám', Icons.task_alt, hasVisit, finishExam),
            toolButton(
              'Chuyển nội trú',
              Icons.bed_outlined,
              hasVisit && selectedVisit?['status'] != 'ADMITTED',
              admitSelectedVisit,
            ),
            toolButton(
              'Next',
              Icons.skip_next_outlined,
              visits.isNotEmpty,
              nextPatient,
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
  ) {
    return InkWell(
      onTap: enabled && !busy ? action : null,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFFBCD3EA))),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: enabled ? const Color(0xFF0F172A) : Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
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
        color: Colors.white,
        border: Border.all(color: const Color(0xFFBCD3EA)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: pickDate,
            icon: const Icon(Icons.calendar_month, size: 17),
            label: Text(displayDate(selectedDate)),
          ),
          filterDropdown(
            width: 180,
            value: departmentId,
            hint: 'Khoa',
            items: departments
                .map((item) => dropdown(item.id, item.data['name']))
                .toList(),
            onChanged: (value) {
              setState(() {
                departmentId = value;
                roomId = null;
                doctorId = null;
              });
              loadWorkspace(preserveSelection: false);
            },
          ),
          filterDropdown(
            width: 160,
            value: roomId,
            hint: 'Phòng',
            items: availableRooms
                .map((item) => dropdown(item.id, item.data['name']))
                .toList(),
            onChanged: (value) {
              setState(() => roomId = value);
              loadWorkspace(preserveSelection: false);
            },
          ),
          filterDropdown(
            width: 180,
            value: doctorId,
            hint: 'Bác sĩ',
            items: availableDoctors
                .map((item) => dropdown(item.id, item.data['fullName']))
                .toList(),
            onChanged: (value) {
              setState(() => doctorId = value);
              loadWorkspace(preserveSelection: false);
            },
          ),
          filterDropdown(
            width: 170,
            value: status,
            hint: 'Trạng thái',
            includeAll: false,
            items: const [
              DropdownMenuItem(value: 'WAITING_EXAM', child: Text('Chờ khám')),
              DropdownMenuItem(value: 'IN_EXAM', child: Text('Đang khám')),
              DropdownMenuItem(value: 'WAITING_CLS', child: Text('Chờ CLS')),
              DropdownMenuItem(
                value: 'WAITING_PAYMENT',
                child: Text('Chờ thanh toán'),
              ),
              DropdownMenuItem(value: 'COMPLETED', child: Text('Hoàn tất')),
            ],
            onChanged: (value) {
              setState(() => status = value ?? 'WAITING_EXAM');
              loadWorkspace(preserveSelection: false);
            },
          ),
          IconButton(
            tooltip: 'Tải lại',
            onPressed: loadWorkspace,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget filterDropdown({
    required double width,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    bool includeAll = true,
  }) {
    final values = items.map((item) => item.value).toSet();
    final safeValue = values.contains(value) ? value : null;
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$hint-$safeValue-${items.length}'),
        initialValue: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          if (includeAll)
            const DropdownMenuItem(value: null, child: Text('Tất cả')),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }

  DropdownMenuItem<String> dropdown(String value, dynamic label) {
    return DropdownMenuItem(value: value, child: Text(label?.toString() ?? ''));
  }

  List<AdminRecord> get availableRooms {
    final departmentName = departments
        .where((item) => item.id == departmentId)
        .map((item) => item.data['name']?.toString())
        .firstOrNull;
    return rooms
        .where(
          (item) =>
              departmentName == null ||
              item.data['department']?.toString() == departmentName,
        )
        .toList();
  }

  List<AdminRecord> get availableDoctors {
    final departmentName = departments
        .where((item) => item.id == departmentId)
        .map((item) => item.data['name']?.toString())
        .firstOrNull;
    return doctors
        .where(
          (item) =>
              departmentName == null ||
              item.data['department']?.toString() == departmentName,
        )
        .toList();
  }

  Widget visitList() {
    return panel(
      title: 'Danh sách bệnh nhân',
      child: visits.isEmpty
          ? const SizedBox(
              height: 180,
              child: Center(child: Text('Không có lượt khám phù hợp')),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 42,
                dataRowMaxHeight: 52,
                columnSpacing: 14,
                columns: const [
                  DataColumn(label: Text('STT')),
                  DataColumn(label: Text('Mã lượt')),
                  DataColumn(label: Text('Mã BN')),
                  DataColumn(label: Text('Họ tên')),
                  DataColumn(label: Text('Năm sinh')),
                  DataColumn(label: Text('Giới')),
                  DataColumn(label: Text('Lý do khám')),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('Chờ')),
                ],
                rows: visits.asMap().entries.map((entry) {
                  final item = entry.value;
                  final active = item['id'] == selectedVisit?['id'];
                  return DataRow(
                    selected: active,
                    onSelectChanged: (_) => selectVisit(item),
                    cells: [
                      DataCell(Text('${entry.key + 1}')),
                      DataCell(Text(item['visitCode']?.toString() ?? '')),
                      DataCell(Text(item['patientCode']?.toString() ?? '')),
                      DataCell(Text(item['patient']?.toString() ?? '')),
                      DataCell(Text(birthYear(item['patientDob']))),
                      DataCell(Text(genderText(item['patientGender']))),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            item['reason']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(statusPill(item['status']?.toString() ?? '')),
                      DataCell(Text(waitTime(item))),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget clinicalWorkspace() {
    return panel(
      title: 'Hồ sơ khám bệnh',
      child: selectedVisit == null
          ? const SizedBox(
              height: 300,
              child: Center(child: Text('Chọn bệnh nhân để mở bệnh án')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                patientStrip(),
                const SizedBox(height: 6),
                tabBar(),
                const SizedBox(height: 8),
                tabContent(),
              ],
            ),
    );
  }

  Widget patientStrip() {
    final item = selectedVisit!;
    return Container(
      padding: const EdgeInsets.all(9),
      color: const Color(0xFFEAF2FA),
      child: Wrap(
        spacing: 20,
        runSpacing: 6,
        children: [
          stripValue('Mã BN', item['patientCode']),
          stripValue('Họ tên', item['patient']),
          stripValue('Tuổi', age(item['patientDob'])),
          stripValue('Giới', genderText(item['patientGender'])),
          stripValue('Số BHYT', item['insuranceNumber']),
          stripValue('Khoa', item['department']),
          stripValue('Phòng', item['roomName']),
          stripValue('Bác sĩ', item['doctor']),
        ],
      ),
    );
  }

  Widget stripValue(String label, dynamic value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          TextSpan(text: value?.toString() ?? ''),
        ],
      ),
    );
  }

  Widget tabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final active = activeTab == tab;
          return InkWell(
            onTap: () => setState(() => activeTab = tab),
            child: Container(
              height: 34,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: active ? const Color(0xFF0059A6) : const Color(0xFFF1F5F9),
              child: Text(
                tab,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF334155),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget tabContent() {
    switch (activeTab) {
      case 'Bệnh án':
        return medicalRecordForm();
      case 'Chỉ định':
        return serviceOrderTab();
      case 'Thuốc':
        return DoctorPrescriptionTab(
          key: ValueKey('${selectedVisit?['id']}-${encounter?['id']}'),
          service: widget.service,
          visit: selectedVisit!,
          encounter: encounter,
        );
      case 'Hành chính':
        return administrativeTab();
      case 'Sinh hiệu':
        return emptyTab('Sinh hiệu được ghi nhận theo Encounter.');
      case 'Xét nghiệm':
        return diagnosticResults(
          title: 'Kết quả xét nghiệm',
          rows: labResults,
          detailBuilder: labResultDetail,
        );
      case 'CĐHA':
        return diagnosticResults(
          title: 'Kết quả CĐHA',
          rows: imagingResults,
          detailBuilder: imagingResultDetail,
        );
      case 'Viện phí':
        return DoctorBillingTab(
          key: ValueKey('billing-${selectedVisit?['id']}'),
          service: widget.service,
          visitId: selectedVisit!['id'].toString(),
        );
      case 'Lịch sử':
        return relatedList(
          'Lịch sử phiên khám',
          encounters,
          'encounterCode',
          'status',
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget medicalRecordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        formField('Lý do khám', 'chiefComplaint', lines: 2),
        formField('Quá trình bệnh lý', 'pathologicalProcess', lines: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: formField('Tiền sử bản thân', 'personalHistory', lines: 3),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: formField('Tiền sử gia đình', 'familyHistory', lines: 3),
            ),
          ],
        ),
        formField('Dị ứng', 'allergies', lines: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: formField('Khám toàn thân', 'generalExam', lines: 3),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: formField('Khám bộ phận', 'specializedExam', lines: 3),
            ),
          ],
        ),
        formField('Khám lâm sàng', 'clinicalSigns', lines: 3),
        formField('Chẩn đoán sơ bộ', 'preliminaryDiagnosis', lines: 2),
        Row(
          children: [
            Expanded(child: formField('ICD-10', 'diagnosisCode')),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: formField('Chẩn đoán chính *', 'diagnosisText'),
            ),
          ],
        ),
        formField('Chẩn đoán phụ', 'secondaryDiagnosis', lines: 2),
        formField('Xử trí *', 'treatmentPlan', lines: 3),
        formField('Lời dặn', 'instructions', lines: 2),
        formField('Kết luận *', 'conclusion', lines: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: busy ? null : saveMedicalRecord,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Lưu bệnh án'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: busy ? null : finishExam,
              icon: const Icon(Icons.task_alt),
              label: const Text('Hoàn tất khám'),
            ),
          ],
        ),
      ],
    );
  }

  Widget serviceOrderTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            orderButton('Thêm xét nghiệm', Icons.biotech, 'LAB'),
            orderButton('Thêm CĐHA', Icons.image_search, 'IMAGING'),
            orderButton(
              'Thêm dịch vụ kỹ thuật',
              Icons.medical_services_outlined,
              'PROCEDURE',
            ),
            orderButton('Thêm vật tư', Icons.inventory_2_outlined, 'SUPPLY'),
          ],
        ),
        const SizedBox(height: 8),
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Chưa có phiếu chỉ định')),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 72,
              columnSpacing: 16,
              columns: const [
                DataColumn(label: Text('Mã phiếu')),
                DataColumn(label: Text('Loại')),
                DataColumn(label: Text('Tên dịch vụ')),
                DataColumn(label: Text('SL')),
                DataColumn(label: Text('Thành tiền')),
                DataColumn(label: Text('BHYT trả')),
                DataColumn(label: Text('BN trả')),
                DataColumn(label: Text('Thanh toán')),
                DataColumn(label: Text('Thực hiện')),
                DataColumn(label: Text('')),
              ],
              rows: orders.expand((order) {
                final items = (order['items'] as List? ?? const []);
                return items.asMap().entries.map((entry) {
                  final item = Map<String, dynamic>.from(entry.value as Map);
                  final first = entry.key == 0;
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(first ? order['orderCode']?.toString() ?? '' : ''),
                      ),
                      DataCell(
                        Text(first ? orderTypeText(order['orderType']) : ''),
                      ),
                      DataCell(
                        SizedBox(
                          width: 210,
                          child: Text(item['itemName']?.toString() ?? ''),
                        ),
                      ),
                      DataCell(Text('${item['quantity'] ?? 0}')),
                      DataCell(Text(money(item['amount']))),
                      DataCell(Text(money(item['insurancePayAmount']))),
                      DataCell(Text(money(item['patientPayAmount']))),
                      DataCell(
                        Text(
                          paymentStatusText(order['status']?.toString() ?? ''),
                        ),
                      ),
                      DataCell(
                        Text(
                          executionStatusText(
                            order['status']?.toString() ?? '',
                          ),
                        ),
                      ),
                      DataCell(
                        first
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'submit') {
                                    submitOrder(order['id'].toString());
                                  } else if (value == 'cancel') {
                                    cancelOrder(order['id'].toString());
                                  }
                                },
                                itemBuilder: (_) => [
                                  if ([
                                    'DRAFT',
                                    'ORDERED',
                                    'WAITING_PAYMENT',
                                  ].contains(order['status']))
                                    const PopupMenuItem(
                                      value: 'submit',
                                      child: Text('Gửi phiếu'),
                                    ),
                                  if (![
                                    'COMPLETED',
                                    'CANCELLED',
                                  ].contains(order['status']))
                                    const PopupMenuItem(
                                      value: 'cancel',
                                      child: Text('Hủy phiếu'),
                                    ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                });
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget orderButton(String label, IconData icon, String type) {
    return OutlinedButton.icon(
      onPressed: selectedVisit?['status'] == 'IN_EXAM'
          ? () => showServiceOrderDialog(type)
          : null,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Future<List<Map<String, dynamic>>> catalogFor(String type) {
    return switch (type) {
      'LAB' => widget.service.loadLabServices(),
      'IMAGING' => widget.service.loadImagingServices(),
      'SUPPLY' => widget.service.loadSupplies(),
      _ => widget.service.loadTechnicalServices(),
    };
  }

  Future<void> showServiceOrderDialog(String type) async {
    if (encounter == null) {
      showMessage('Cần bắt đầu khám để tạo Encounter trước', error: true);
      return;
    }
    setState(() => busy = true);
    List<Map<String, dynamic>> catalog;
    try {
      catalog = await catalogFor(type);
    } catch (error) {
      showMessage(error.toString(), error: true);
      if (mounted) setState(() => busy = false);
      return;
    }
    if (mounted) setState(() => busy = false);

    final searchController = TextEditingController();
    final noteController = TextEditingController();
    final selected = <String, Map<String, dynamic>>{};
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final query = searchController.text.trim().toLowerCase();
          final filtered = catalog.where((item) {
            return query.isEmpty ||
                item['name'].toString().toLowerCase().contains(query) ||
                item['code'].toString().toLowerCase().contains(query);
          }).toList();
          final total = selected.values.fold<int>(
            0,
            (sum, item) =>
                sum + ((item['price'] as int) * (item['quantity'] as int)),
          );
          return AlertDialog(
            title: Text('Thêm ${orderTypeText(type)}'),
            content: SizedBox(
              width: 900,
              height: 560,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Tìm mã hoặc tên dịch vụ',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final item = filtered[index];
                              final id = item['id'].toString();
                              final checked = selected.containsKey(id);
                              return CheckboxListTile(
                                dense: true,
                                value: checked,
                                title: Text(
                                  '${item['code'] ?? ''} - ${item['name'] ?? ''}',
                                ),
                                subtitle: Text(money(item['price'])),
                                onChanged: (_) => setDialogState(() {
                                  if (checked) {
                                    selected.remove(id);
                                  } else {
                                    selected[id] = {
                                      ...item,
                                      'quantity': 1,
                                      'insuranceCovered':
                                          selectedVisit?['insuranceUsed'] ==
                                          true,
                                    };
                                  }
                                }),
                              );
                            },
                          ),
                        ),
                        const VerticalDivider(),
                        Expanded(
                          child: selected.isEmpty
                              ? const Center(child: Text('Chưa chọn dịch vụ'))
                              : ListView(
                                  children: selected.values.map((item) {
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['name'].toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Text('Số lượng'),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed:
                                                      item['quantity'] > 1
                                                      ? () => setDialogState(
                                                          () =>
                                                              item['quantity']--,
                                                        )
                                                      : null,
                                                  icon: const Icon(
                                                    Icons.remove,
                                                  ),
                                                ),
                                                Text('${item['quantity']}'),
                                                IconButton(
                                                  onPressed: () =>
                                                      setDialogState(
                                                        () =>
                                                            item['quantity']++,
                                                      ),
                                                  icon: const Icon(Icons.add),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  money(
                                                    item['price'] *
                                                        item['quantity'],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            CheckboxListTile(
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                              value:
                                                  item['insuranceCovered'] ==
                                                  true,
                                              title: const Text(
                                                'BHYT có chi trả',
                                              ),
                                              onChanged:
                                                  selectedVisit?['insuranceUsed'] ==
                                                      true
                                                  ? (value) => setDialogState(
                                                      () =>
                                                          item['insuranceCovered'] =
                                                              value == true,
                                                    )
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Tổng dự kiến: ${money(total)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
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
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(dialogContext, {
                        'note': noteController.text.trim(),
                        'items': selected.values.toList(),
                      }),
                child: const Text('Tạo phiếu chỉ định'),
              ),
            ],
          );
        },
      ),
    );
    searchController.dispose();
    noteController.dispose();
    if (result == null) return;

    setState(() => busy = true);
    try {
      await widget.service.createServiceOrder(selectedVisit!['id'].toString(), {
        'encounterId': encounter!['id'],
        'orderType': type,
        'note': result['note'],
        'items': (result['items'] as List).map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          return {
            'itemType': type,
            'itemId': item['id'],
            'itemName': item['name'],
            'quantity': item['quantity'],
            'unitPrice': item['price'],
            'insuranceCovered': item['insuranceCovered'],
          };
        }).toList(),
      });
      orders = await widget.service.loadVisitOrders(
        selectedVisit!['id'].toString(),
      );
      if (mounted) setState(() {});
      showMessage('Đã tạo phiếu chỉ định');
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> submitOrder(String id) async {
    try {
      await widget.service.submitServiceOrder(id);
      orders = await widget.service.loadVisitOrders(
        selectedVisit!['id'].toString(),
      );
      if (mounted) setState(() {});
    } catch (error) {
      showMessage(error.toString(), error: true);
    }
  }

  Future<void> cancelOrder(String id) async {
    try {
      await widget.service.cancelServiceOrder(id);
      orders = await widget.service.loadVisitOrders(
        selectedVisit!['id'].toString(),
      );
      if (mounted) setState(() {});
    } catch (error) {
      showMessage(error.toString(), error: true);
    }
  }

  String orderTypeText(dynamic value) {
    return switch (value?.toString()) {
      'LAB' => 'Xét nghiệm',
      'IMAGING' => 'CĐHA',
      'SUPPLY' => 'Vật tư',
      'PROCEDURE' => 'Dịch vụ kỹ thuật',
      _ => value?.toString() ?? '',
    };
  }

  String paymentStatusText(String value) {
    return switch (value) {
      'WAITING_PAYMENT' => 'Chờ thanh toán',
      'PAID' => 'Đã thanh toán',
      'CANCELLED' => 'Đã hủy',
      _ => 'Không yêu cầu/Đã gửi',
    };
  }

  String executionStatusText(String value) {
    return switch (value) {
      'WAITING_PAYMENT' => 'Chờ thanh toán',
      'CANCELLED' => 'Đã hủy',
      'COMPLETED' => 'Hoàn tất',
      _ => 'Chờ thực hiện',
    };
  }

  String money(dynamic value) {
    final number = int.tryParse(value?.toString() ?? '') ?? 0;
    final text = number.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < text.length; index++) {
      if (index > 0 && (text.length - index) % 3 == 0) buffer.write('.');
      buffer.write(text[index]);
    }
    return '${buffer.toString()} đ';
  }

  Widget formField(String label, String key, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controllers[key],
        minLines: lines,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          alignLabelWithHint: lines > 1,
        ),
      ),
    );
  }

  Widget administrativeTab() {
    final item = selectedVisit!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        infoBox('Mã lượt khám', item['visitCode']),
        infoBox('Mã bệnh nhân', item['patientCode']),
        infoBox('Họ tên', item['patient']),
        infoBox('Ngày sinh', displayApiDate(item['patientDob'])),
        infoBox('Giới tính', genderText(item['patientGender'])),
        infoBox('Số BHYT', item['insuranceNumber']),
        infoBox('Tiếp nhận', displayApiDateTime(item['receptionTime'])),
      ],
    );
  }

  Widget infoBox(String label, dynamic value) {
    return SizedBox(
      width: 220,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(value?.toString() ?? ''),
      ),
    );
  }

  Widget relatedList(
    String title,
    List<Map<String, dynamic>> rows,
    String primary,
    String secondary, {
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const Spacer(),
            if (action != null) action,
          ],
        ),
        const SizedBox(height: 6),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text('Chưa có dữ liệu')),
          )
        else
          ...rows.map(
            (item) => ListTile(
              dense: true,
              title: Text(item[primary]?.toString() ?? ''),
              subtitle: Text(item[secondary]?.toString() ?? ''),
            ),
          ),
      ],
    );
  }

  Widget diagnosticResults({
    required String title,
    required List<Map<String, dynamic>> rows,
    required Widget Function(Map<String, dynamic>) detailBuilder,
  }) {
    if (rows.isEmpty) {
      return emptyTab('Chưa có $title theo lượt khám này.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...rows.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              initiallyExpanded: rows.length == 1,
              title: Text(
                item['serviceName']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${item['orderCode'] ?? ''} • ${diagnosticStatusText(item['status']?.toString() ?? '')}',
              ),
              trailing: item['status'] == 'APPROVED'
                  ? const Icon(Icons.verified, color: Colors.green)
                  : const Icon(Icons.pending_actions, color: Colors.orange),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: detailBuilder(item),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget labResultDetail(Map<String, dynamic> item) {
    final indicators = item['indicators'] as List? ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (indicators.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 36,
              dataRowMinHeight: 38,
              columns: const [
                DataColumn(label: Text('Chỉ số')),
                DataColumn(label: Text('Kết quả')),
                DataColumn(label: Text('Đơn vị')),
                DataColumn(label: Text('Khoảng tham chiếu')),
              ],
              rows: indicators.map((value) {
                final row = Map<String, dynamic>.from(value as Map);
                final reference =
                    row['referenceText']?.toString().isNotEmpty == true
                    ? row['referenceText'].toString()
                    : '${row['normalMin'] ?? ''} - ${row['normalMax'] ?? ''}';
                return DataRow(
                  cells: [
                    DataCell(Text(row['name']?.toString() ?? '')),
                    DataCell(Text(row['value']?.toString() ?? '')),
                    DataCell(Text(row['unit']?.toString() ?? '')),
                    DataCell(Text(reference)),
                  ],
                );
              }).toList(),
            ),
          ),
        resultLine('Kết quả', item['resultText']),
        resultLine('Kết luận', item['conclusion']),
        resultLine('Người thực hiện', item['performedBy']),
        resultLine('Người duyệt', item['approvedBy']),
      ],
    );
  }

  Widget imagingResultDetail(Map<String, dynamic> item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        resultLine('Kỹ thuật', item['technique']),
        resultLine('Mô tả hình ảnh', item['description']),
        resultLine('Kết luận', item['conclusion']),
        resultLine('Bác sĩ đọc', item['readerName']),
        resultLine('Bác sĩ duyệt', item['approverName']),
        if (item['attachmentUrl']?.toString().isNotEmpty == true)
          resultLine('File ảnh/PDF', item['attachmentUrl']),
      ],
    );
  }

  Widget resultLine(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(text: value?.toString() ?? ''),
          ],
        ),
      ),
    );
  }

  String diagnosticStatusText(String value) =>
      const {
        'WAITING_SAMPLE': 'Chờ lấy mẫu',
        'SAMPLE_TAKEN': 'Đã lấy mẫu',
        'RUNNING': 'Đang chạy',
        'WAITING': 'Chờ thực hiện',
        'PERFORMED': 'Đã thực hiện',
        'WAITING_READ': 'Chờ đọc',
        'WAITING_APPROVAL': 'Chờ duyệt',
        'APPROVED': 'Đã duyệt',
        'CANCELLED': 'Đã hủy',
      }[value] ??
      value;

  Widget emptyTab(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      color: const Color(0xFFF8FAFC),
      child: Text(message, textAlign: TextAlign.center),
    );
  }

  Widget panel({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFBCD3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            color: const Color(0xFFE9F2FA),
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

  Widget statusPill(String value) {
    final color = switch (value) {
      'WAITING_EXAM' => Colors.orange,
      'IN_EXAM' => Colors.blue,
      'WAITING_PAYMENT' => Colors.purple,
      'COMPLETED' => Colors.green,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      color: color.withValues(alpha: 0.12),
      child: Text(
        statusText(value),
        style: TextStyle(color: color.shade700, fontWeight: FontWeight.w800),
      ),
    );
  }

  Future<void> pickDate() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: selectedDate,
    );
    if (value == null) return;
    setState(() => selectedDate = value);
    await loadWorkspace(preserveSelection: false);
  }

  String apiDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String displayApiDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null ? '' : displayDate(date);
  }

  String displayApiDateTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    return '${displayDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String birthYear(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date?.year.toString() ?? '';
  }

  String age(dynamic value) {
    final dob = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (dob == null) return '';
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return '$years';
  }

  String genderText(dynamic value) {
    return switch (value?.toString().toUpperCase()) {
      'MALE' || 'NAM' => 'Nam',
      'FEMALE' || 'NỮ' || 'NU' => 'Nữ',
      _ => value?.toString() ?? '',
    };
  }

  String statusText(String value) {
    return switch (value) {
      'WAITING_EXAM' => 'Chờ khám',
      'IN_EXAM' => 'Đang khám',
      'WAITING_PAYMENT' => 'Chờ thanh toán',
      'COMPLETED' => 'Hoàn tất',
      _ => value,
    };
  }

  String waitTime(Map<String, dynamic> item) {
    final from = DateTime.tryParse(item['receptionTime']?.toString() ?? '');
    final to =
        DateTime.tryParse(item['startExamTime']?.toString() ?? '') ??
        DateTime.now();
    if (from == null) return '';
    final minutes = to.difference(from).inMinutes.clamp(0, 9999);
    return '$minutes phút';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
