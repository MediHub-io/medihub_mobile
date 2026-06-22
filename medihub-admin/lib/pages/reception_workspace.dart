import 'dart:async';

import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';
import '../core/admin_models.dart';

class ReceptionWorkspace extends StatefulWidget {
  final AdminApiService service;

  const ReceptionWorkspace({super.key, required this.service});

  @override
  State<ReceptionWorkspace> createState() => _ReceptionWorkspaceState();
}

class _ReceptionWorkspaceState extends State<ReceptionWorkspace> {
  final patientSearchController = TextEditingController();
  final reasonController = TextEditingController();
  final noteController = TextEditingController();
  final insuranceController = TextEditingController();
  Timer? searchDebounce;

  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> visits = [];
  List<Map<String, dynamic>> queueTickets = [];
  List<AdminRecord> departments = [];
  List<AdminRecord> rooms = [];
  List<AdminRecord> doctors = [];

  Map<String, dynamic>? selectedPatient;
  Map<String, dynamic>? selectedAppointment;
  String? visitType = 'OUTPATIENT';
  String? departmentId;
  String? roomId;
  String? doctorId;
  bool insuranceUsed = false;
  bool loading = true;
  bool submitting = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadWorkspace();
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    patientSearchController.dispose();
    reasonController.dispose();
    noteController.dispose();
    insuranceController.dispose();
    super.dispose();
  }

  Future<void> loadWorkspace() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final results = await Future.wait([
        widget.service.loadTodayAppointments(),
        widget.service.loadReceptionVisits(),
        widget.service.loadQueueTickets(),
        widget.service.lookup(AdminRoute.departments),
        widget.service.lookup(AdminRoute.rooms),
        widget.service.lookup(AdminRoute.doctors),
      ]);
      if (!mounted) return;
      setState(() {
        appointments = results[0] as List<Map<String, dynamic>>;
        visits = results[1] as List<Map<String, dynamic>>;
        queueTickets = results[2] as List<Map<String, dynamic>>;
        departments = results[3] as List<AdminRecord>;
        rooms = results[4] as List<AdminRecord>;
        doctors = results[5] as List<AdminRecord>;
      });
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void searchPatients(String value) {
    searchDebounce?.cancel();
    searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final keyword = value.trim();
      if (keyword.isEmpty) {
        if (mounted) setState(() => patients = []);
        return;
      }
      try {
        final result = await widget.service.searchPatients(keyword);
        if (mounted) setState(() => patients = result);
      } catch (error) {
        if (mounted) setState(() => errorMessage = error.toString());
      }
    });
  }

  void selectPatient(Map<String, dynamic> patient) {
    setState(() {
      selectedPatient = patient;
      selectedAppointment = null;
      insuranceController.text =
          patient['insuranceNo']?.toString() ??
          patient['insuranceNumber']?.toString() ??
          '';
      patients = [];
      patientSearchController.text =
          '${patient['patientCode'] ?? ''} - ${patient['fullName'] ?? patient['patient'] ?? ''}';
    });
  }

  void selectAppointment(Map<String, dynamic> appointment) {
    setState(() {
      selectedAppointment = appointment;
      selectedPatient = {
        'id': appointment['patientId'],
        'patientCode': appointment['patientCode'],
        'fullName': appointment['patient'],
        'phone': appointment['patientPhone'],
        'insuranceNo': appointment['insuranceNumber'],
      };
      visitType = 'OUTPATIENT';
      departmentId = emptyToNull(appointment['departmentId']);
      doctorId = emptyToNull(appointment['doctorId']);
      roomId = null;
      reasonController.text = appointment['reason']?.toString() ?? '';
      insuranceController.text =
          appointment['insuranceNumber']?.toString() ?? '';
      insuranceUsed = insuranceController.text.trim().isNotEmpty;
    });
  }

  String? emptyToNull(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  List<AdminRecord> get availableRooms {
    return rooms.where((room) {
      final roomDepartment = room.data['department']?.toString() ?? '';
      final department = selectedDepartment;
      return departmentId == null ||
          roomDepartment.isEmpty ||
          roomDepartment == department?.data['name'];
    }).toList();
  }

  List<AdminRecord> get availableDoctors {
    return doctors.where((doctor) {
      final doctorDepartment = doctor.data['department']?.toString() ?? '';
      final department = selectedDepartment;
      return departmentId == null ||
          doctorDepartment.isEmpty ||
          doctorDepartment == department?.data['name'];
    }).toList();
  }

  AdminRecord? get selectedDepartment {
    for (final item in departments) {
      if (item.id == departmentId) return item;
    }
    return null;
  }

  Future<void> submitReception() async {
    final patientId = selectedPatient?['id']?.toString() ?? '';
    final reason = reasonController.text.trim();
    if (patientId.isEmpty) return showError('Chưa chọn hoặc tạo bệnh nhân');
    if (visitType == null || visitType!.isEmpty) {
      return showError('Chưa chọn loại khám');
    }
    if (departmentId == null) return showError('Chưa chọn khoa khám');
    if (reason.isEmpty) return showError('Chưa nhập lý do khám');
    if (insuranceUsed && insuranceController.text.trim().isEmpty) {
      return showError('Vui lòng nhập số BHYT');
    }

    setState(() {
      submitting = true;
      errorMessage = null;
    });
    final data = {
      'patientId': patientId,
      'visitType': visitType,
      'departmentId': departmentId,
      'roomId': roomId,
      'doctorId': doctorId,
      'reason': reason,
      'note': noteController.text.trim(),
      'insuranceUsed': insuranceUsed,
      'insuranceNumber': insuranceController.text.trim(),
    };
    try {
      if (selectedAppointment != null) {
        await widget.service.convertAppointmentToVisit(
          selectedAppointment!['id'].toString(),
          data: data,
        );
      } else {
        await widget.service.createVisit(data);
      }
      await loadWorkspace();
      if (!mounted) return;
      clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tiếp nhận và tạo lượt khám')),
      );
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void clearForm() {
    setState(() {
      selectedPatient = null;
      selectedAppointment = null;
      patientSearchController.clear();
      patients = [];
      visitType = 'OUTPATIENT';
      departmentId = null;
      roomId = null;
      doctorId = null;
      insuranceUsed = false;
      insuranceController.clear();
      reasonController.clear();
      noteController.clear();
    });
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> showQuickPatientDialog() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final citizenId = TextEditingController();
    final insurance = TextEditingController();
    String? gender;
    DateTime? dob;

    final patient = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo bệnh nhân mới'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phone,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: citizenId,
                          decoration: const InputDecoration(
                            labelText: 'CCCD',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: gender,
                          decoration: const InputDecoration(
                            labelText: 'Giới tính',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                            DropdownMenuItem(
                              value: 'FEMALE',
                              child: Text('Nữ'),
                            ),
                            DropdownMenuItem(
                              value: 'OTHER',
                              child: Text('Khác'),
                            ),
                          ],
                          onChanged: (value) =>
                              setDialogState(() => gender = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final value = await showDatePicker(
                              context: context,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              initialDate: DateTime(1990),
                            );
                            if (value != null) {
                              setDialogState(() => dob = value);
                            }
                          },
                          icon: const Icon(Icons.cake_outlined),
                          label: Text(
                            dob == null ? 'Ngày sinh' : formatDate(dob),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: insurance,
                    decoration: const InputDecoration(
                      labelText: 'Số BHYT',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) {
                  showError('Vui lòng nhập họ tên bệnh nhân');
                  return;
                }
                try {
                  final result = await widget.service.createPatientQuick({
                    'fullName': name.text.trim(),
                    'phone': phone.text.trim(),
                    'citizenId': citizenId.text.trim(),
                    'insuranceNumber': insurance.text.trim(),
                    'gender': gender,
                    'dob': dob?.toIso8601String(),
                  });
                  if (context.mounted) Navigator.pop(context, result);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.toString())));
                  }
                }
              },
              child: const Text('Tạo bệnh nhân'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    citizenId.dispose();
    insurance.dispose();
    if (patient != null) selectPatient(patient);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.red.shade50,
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (loading) const LinearProgressIndicator(minHeight: 2),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 1100;
            final left = Column(
              children: [
                patientSearchPanel(),
                const SizedBox(height: 8),
                appointmentsPanel(),
              ],
            );
            final right = receptionForm();
            if (stacked) {
              return Column(children: [left, const SizedBox(height: 8), right]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: left),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: right),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        todayVisitsPanel(),
      ],
    );
  }

  Widget section({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCAD6E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFFE9F2FA),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF0059A6)),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                if (action != null) action,
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(10), child: child),
        ],
      ),
    );
  }

  Widget patientSearchPanel() {
    return section(
      title: '1. Tìm bệnh nhân',
      icon: Icons.person_search_outlined,
      action: TextButton.icon(
        onPressed: showQuickPatientDialog,
        icon: const Icon(Icons.person_add_alt_1, size: 17),
        label: const Text('Tạo bệnh nhân mới'),
      ),
      child: Column(
        children: [
          TextField(
            controller: patientSearchController,
            onChanged: searchPatients,
            decoration: const InputDecoration(
              hintText: 'Tìm mã BN / tên / SĐT / CCCD / BHYT',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (patients.isNotEmpty) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: patients.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${patient['patientCode'] ?? ''} - ${patient['fullName'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                            patient['phone'],
                            patient['citizenId'],
                            patient['insuranceNo'],
                          ]
                          .where(
                            (value) => value?.toString().isNotEmpty == true,
                          )
                          .join(' • '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => selectPatient(patient),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget appointmentsPanel() {
    return section(
      title: '2. Lịch hẹn hôm nay',
      icon: Icons.event_available_outlined,
      action: IconButton(
        tooltip: 'Tải lại',
        onPressed: loadWorkspace,
        icon: const Icon(Icons.refresh, size: 18),
      ),
      child: table(
        columns: const [
          'Giờ hẹn',
          'Mã BN',
          'Họ tên',
          'Khoa',
          'Bác sĩ',
          'Trạng thái',
          '',
        ],
        rows: appointments.map((item) {
          return [
            formatTime(item['appointmentDate']),
            item['patientCode'] ?? '',
            item['patient'] ?? '',
            item['department'] ?? '',
            item['doctor'] ?? '',
            item['status'] ?? '',
            TextButton(
              onPressed: () => selectAppointment(item),
              child: const Text('Tiếp nhận'),
            ),
          ];
        }).toList(),
        emptyText: 'Không có lịch hẹn đã xác nhận hôm nay',
      ),
    );
  }

  Widget receptionForm() {
    return section(
      title: '3. Form tiếp nhận',
      icon: Icons.how_to_reg_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            color: const Color(0xFFF6F8FA),
            child: selectedPatient == null
                ? const Text('Chưa chọn bệnh nhân')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedPatient!['patientCode'] ?? ''} - ${selectedPatient!['fullName'] ?? selectedPatient!['patient'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(selectedPatient!['phone']?.toString() ?? ''),
                      if (selectedAppointment != null)
                        const Text(
                          'Nguồn: Lịch hẹn đã xác nhận',
                          style: TextStyle(color: Color(0xFF0059A6)),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: visitType,
            decoration: fieldDecoration('Loại khám *'),
            items: const [
              DropdownMenuItem(value: 'OUTPATIENT', child: Text('Ngoại trú')),
              DropdownMenuItem(value: 'EMERGENCY', child: Text('Cấp cứu')),
              DropdownMenuItem(value: 'INPATIENT', child: Text('Nội trú')),
            ],
            onChanged: (value) => setState(() => visitType = value),
          ),
          const SizedBox(height: 9),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Dịch vụ')),
              ButtonSegment(value: true, label: Text('BHYT')),
            ],
            selected: {insuranceUsed},
            onSelectionChanged: (value) =>
                setState(() => insuranceUsed = value.first),
          ),
          if (insuranceUsed) ...[
            const SizedBox(height: 9),
            TextField(
              controller: insuranceController,
              decoration: fieldDecoration('Số BHYT *'),
            ),
          ],
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            key: ValueKey('department-$departmentId'),
            initialValue: departmentId,
            decoration: fieldDecoration('Khoa khám *'),
            items: departments
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.data['name']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() {
              departmentId = value;
              roomId = null;
              doctorId = null;
            }),
          ),
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            key: ValueKey('room-$departmentId-$roomId'),
            initialValue: availableRooms.any((item) => item.id == roomId)
                ? roomId
                : null,
            decoration: fieldDecoration('Phòng khám'),
            items: availableRooms
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.data['name']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => roomId = value),
          ),
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            key: ValueKey('doctor-$departmentId-$doctorId'),
            initialValue: availableDoctors.any((item) => item.id == doctorId)
                ? doctorId
                : null,
            decoration: fieldDecoration('Bác sĩ'),
            items: availableDoctors
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.data['fullName']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => doctorId = value),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: reasonController,
            maxLines: 2,
            decoration: fieldDecoration('Lý do khám *'),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: fieldDecoration('Ghi chú'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: submitting ? null : submitReception,
            icon: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.how_to_reg),
            label: const Text('Tiếp nhận & tạo lượt khám'),
          ),
          if (selectedPatient != null)
            TextButton(onPressed: clearForm, child: const Text('Làm lại')),
        ],
      ),
    );
  }

  Widget todayVisitsPanel() {
    final ticketByVisit = {
      for (final item in queueTickets)
        if (item['visitId'] != null) item['visitId'].toString(): item,
    };
    return section(
      title: '4. Lượt tiếp nhận hôm nay',
      icon: Icons.format_list_numbered,
      child: table(
        columns: const [
          'Mã lượt khám',
          'Số TT',
          'Mã BN',
          'Họ tên',
          'Khoa',
          'Phòng',
          'Bác sĩ',
          'Trạng thái',
          'Tiếp nhận',
        ],
        rows: visits.map((item) {
          final ticket = ticketByVisit[item['id']?.toString()];
          return [
            item['visitCode'] ?? '',
            ticket?['ticketNumber'] ??
                item['queueTicket']?['ticketNumber'] ??
                '',
            item['patientCode'] ?? '',
            item['patient'] ?? '',
            item['department'] ?? '',
            item['roomName'] ?? '',
            item['doctor'] ?? '',
            item['status'] ?? '',
            formatDateTime(item['receptionTime']),
          ];
        }).toList(),
        emptyText: 'Chưa có lượt tiếp nhận hôm nay',
      ),
    );
  }

  InputDecoration fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
    );
  }

  Widget table({
    required List<String> columns,
    required List<List<dynamic>> rows,
    required String emptyText,
  }) {
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text(emptyText)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 38,
        dataRowMaxHeight: 46,
        columnSpacing: 18,
        columns: columns
            .map((label) => DataColumn(label: Text(label)))
            .toList(),
        rows: rows
            .map(
              (row) => DataRow(
                cells: row.map((value) {
                  return DataCell(
                    value is Widget
                        ? value
                        : Text(value?.toString() ?? '', maxLines: 2),
                  );
                }).toList(),
              ),
            )
            .toList(),
      ),
    );
  }

  String formatDate(DateTime? value) {
    if (value == null) return '';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String formatTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String formatDateTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    return '${formatDate(date)} ${formatTime(date.toIso8601String())}';
  }
}
