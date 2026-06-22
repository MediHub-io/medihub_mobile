import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';
import '../core/admin_models.dart';

class AdmissionWorkspace extends StatefulWidget {
  final AdminApiService service;

  const AdmissionWorkspace({super.key, required this.service});

  @override
  State<AdmissionWorkspace> createState() => _AdmissionWorkspaceState();
}

class _AdmissionWorkspaceState extends State<AdmissionWorkspace> {
  static const tabs = [
    'Thông tin nhập viện',
    'Buồng giường',
    'Diễn biến',
    'Y lệnh',
    'Thuốc',
    'Dịch vụ',
    'Viện phí',
    'Ra viện',
  ];

  final searchController = TextEditingController();
  List<Map<String, dynamic>> admissions = [];
  List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> beds = [];
  List<AdminRecord> departments = [];
  Map<String, dynamic>? selected;
  String? departmentId;
  String? roomId;
  String status = 'ADMITTED';
  String activeTab = 'Thông tin nhập viện';
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
      final results = await Future.wait([
        widget.service.loadAdmissions(
          search: searchController.text.trim(),
          departmentId: departmentId,
          roomId: roomId,
          status: status,
        ),
        widget.service.loadRooms(),
        widget.service.loadBeds(),
        widget.service.lookup(AdminRoute.departments),
      ]);
      final rows = results[0] as List<Map<String, dynamic>>;
      final selectedId = preserveSelection && selected != null
          ? selected!['id']
          : null;
      if (!mounted) return;
      setState(() {
        admissions = rows;
        rooms = results[1] as List<Map<String, dynamic>>;
        beds = results[2] as List<Map<String, dynamic>>;
        departments = results[3] as List<AdminRecord>;
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

  Future<void> chooseBed({required bool transfer}) async {
    final admission = selected;
    if (admission == null) return;
    final available = beds.where((bed) {
      final isCurrent = bed['id'] == admission['bedId'];
      final availableStatus = bed['status'] == 'AVAILABLE';
      final departmentMatches =
          admission['departmentId']?.toString().isEmpty != false ||
          roomDepartmentId(bed['roomName']) == admission['departmentId'];
      return !isCurrent && availableStatus && departmentMatches;
    }).toList();
    if (available.isEmpty) {
      showMessage('Không có giường trống phù hợp', error: true);
      return;
    }
    String? bedId;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(transfer ? 'Chuyển giường' : 'Xếp giường'),
          content: SizedBox(
            width: 520,
            child: DropdownButtonFormField<String>(
              initialValue: bedId,
              decoration: const InputDecoration(
                labelText: 'Giường trống',
                border: OutlineInputBorder(),
              ),
              items: available
                  .map(
                    (bed) => DropdownMenuItem(
                      value: bed['id'].toString(),
                      child: Text(
                        '${bed['roomName'] ?? ''} - ${bed['code'] ?? ''} ${bed['name'] ?? ''}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setDialogState(() => bedId = value),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: bedId == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || bedId == null) return;
    setState(() => busy = true);
    try {
      if (transfer) {
        await widget.service.transferBed(admission['id'].toString(), bedId!);
      } else {
        await widget.service.assignBed(admission['id'].toString(), bedId!);
      }
      showMessage(transfer ? 'Đã chuyển giường' : 'Đã xếp giường');
      await load();
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> transferDepartment() async {
    final admission = selected;
    if (admission == null) return;
    String? nextDepartmentId = admission['departmentId']?.toString();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chuyển khoa'),
          content: SizedBox(
            width: 420,
            child: DropdownButtonFormField<String>(
              initialValue: nextDepartmentId,
              decoration: const InputDecoration(
                labelText: 'Khoa điều trị',
                border: OutlineInputBorder(),
              ),
              items: departments
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.data['name']?.toString() ?? ''),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setDialogState(() => nextDepartmentId = value),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed:
                  nextDepartmentId == null ||
                      nextDepartmentId == admission['departmentId']
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Chuyển khoa'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || nextDepartmentId == null) return;
    setState(() => busy = true);
    try {
      await widget.service.transferAdmissionDepartment(
        admission['id'].toString(),
        nextDepartmentId!,
      );
      showMessage('Đã chuyển khoa, người bệnh chờ xếp giường mới');
      await load();
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> discharge() async {
    final admission = selected;
    if (admission == null) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận ra viện'),
        content: Text(
          'Ra viện cho ${admission['patient']}? Giường hiện tại sẽ chuyển sang trạng thái vệ sinh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ra viện'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    setState(() => busy = true);
    try {
      await widget.service.dischargeAdmission(admission['id'].toString());
      showMessage('Đã cho người bệnh ra viện');
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
            if (constraints.maxWidth < 1100) {
              return Column(
                children: [
                  admissionList(),
                  const SizedBox(height: 6),
                  detail(),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 45, child: admissionList()),
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
    final active =
        selected != null &&
        !['DISCHARGED', 'CANCELLED'].contains(selected?['status']);
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            toolButton(
              'Xếp giường',
              Icons.bed_outlined,
              active && selected?['bedId']?.toString().isEmpty != false,
              () => chooseBed(transfer: false),
            ),
            toolButton(
              'Chuyển giường',
              Icons.swap_horiz,
              active && selected?['bedId']?.toString().isNotEmpty == true,
              () => chooseBed(transfer: true),
            ),
            toolButton(
              'Chuyển khoa',
              Icons.sync_alt,
              active,
              transferDepartment,
            ),
            toolButton('Thêm diễn biến', Icons.note_add_outlined, active, () {
              setState(() => activeTab = 'Diễn biến');
              showMessage('Khu vực diễn biến đã sẵn sàng nhập liệu');
            }),
            toolButton('Tạo y lệnh', Icons.assignment_add, active, () {
              setState(() => activeTab = 'Y lệnh');
              showMessage('Khu vực y lệnh đã sẵn sàng');
            }),
            toolButton('Ra viện', Icons.exit_to_app, active, discharge),
            toolButton(
              'In hồ sơ',
              Icons.print_outlined,
              selected != null,
              () => showMessage(
                'Hồ sơ ${selected?['admissionCode']} đã sẵn sàng để in',
              ),
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
        dropdown(
          width: 190,
          value: departmentId,
          label: 'Khoa',
          items: departments
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(item.data['name']?.toString() ?? ''),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              departmentId = value;
              roomId = null;
            });
            load(preserveSelection: false);
          },
        ),
        dropdown(
          width: 180,
          value: roomId,
          label: 'Phòng',
          items: filteredRooms
              .map(
                (item) => DropdownMenuItem(
                  value: item['id'].toString(),
                  child: Text(item['name']?.toString() ?? ''),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() => roomId = value);
            load(preserveSelection: false);
          },
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
              DropdownMenuItem(value: 'WAITING_BED', child: Text('Chờ giường')),
              DropdownMenuItem(value: 'ADMITTED', child: Text('Đang điều trị')),
              DropdownMenuItem(
                value: 'IN_TREATMENT',
                child: Text('Đang điều trị'),
              ),
              DropdownMenuItem(value: 'DISCHARGED', child: Text('Đã ra viện')),
            ],
            onChanged: (value) {
              setState(() => status = value ?? 'ALL');
              load(preserveSelection: false);
            },
          ),
        ),
        SizedBox(
          width: 280,
          child: TextField(
            controller: searchController,
            onSubmitted: (_) => load(preserveSelection: false),
            decoration: InputDecoration(
              hintText: 'Tìm mã BN / tên',
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
      ],
    ),
  );

  Widget admissionList() => panel(
    'Danh sách nội trú',
    admissions.isEmpty
        ? const SizedBox(
            height: 220,
            child: Center(child: Text('Không có hồ sơ nội trú phù hợp')),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 46,
              columns: const [
                DataColumn(label: Text('Mã BN')),
                DataColumn(label: Text('Họ tên')),
                DataColumn(label: Text('Khoa')),
                DataColumn(label: Text('Phòng')),
                DataColumn(label: Text('Giường')),
                DataColumn(label: Text('Ngày vào')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: admissions.map((item) {
                return DataRow(
                  selected: item['id'] == selected?['id'],
                  onSelectChanged: (_) => setState(() {
                    selected = item;
                    activeTab = 'Thông tin nhập viện';
                  }),
                  cells: [
                    DataCell(Text(item['patientCode']?.toString() ?? '')),
                    DataCell(Text(item['patient']?.toString() ?? '')),
                    DataCell(Text(item['department']?.toString() ?? '')),
                    DataCell(Text(item['roomName']?.toString() ?? '')),
                    DataCell(Text(item['bedCode']?.toString() ?? '')),
                    DataCell(Text(dateTime(item['admittedAt']))),
                    DataCell(statusPill(item['status']?.toString() ?? '')),
                  ],
                );
              }).toList(),
            ),
          ),
  );

  Widget detail() {
    if (selected == null) {
      return panel(
        'Hồ sơ nội trú',
        const SizedBox(
          height: 300,
          child: Center(child: Text('Chọn người bệnh nội trú')),
        ),
      );
    }
    return panel(
      'Hồ sơ nội trú',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          patientStrip(),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.map((tab) {
                final active = tab == activeTab;
                return InkWell(
                  onTap: () => setState(() => activeTab = tab),
                  child: Container(
                    height: 34,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    color: active
                        ? const Color(0xFF0059A6)
                        : const Color(0xFFF1F5F9),
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
          ),
          const SizedBox(height: 8),
          tabContent(),
        ],
      ),
    );
  }

  Widget tabContent() {
    final row = selected!;
    switch (activeTab) {
      case 'Thông tin nhập viện':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            infoBox('Mã hồ sơ', row['admissionCode']),
            infoBox('Ngày vào viện', dateTime(row['admittedAt'])),
            infoBox('Lý do vào viện', row['admissionReason']),
            infoBox('Chẩn đoán', row['diagnosis']),
            infoBox('Bác sĩ điều trị', row['doctor']),
            infoBox('Ghi chú', row['note']),
          ],
        );
      case 'Buồng giường':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            infoBox('Khoa', row['department']),
            infoBox('Phòng', row['roomName']),
            infoBox('Giường', row['bedCode']),
            infoBox(
              'Trạng thái giường',
              bedById(row['bedId'])?['status'] ?? '',
            ),
          ],
        );
      case 'Ra viện':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            infoBox(
              'Ngày ra viện',
              row['dischargedAt'] == null
                  ? 'Chưa ra viện'
                  : dateTime(row['dischargedAt']),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: row['status'] == 'DISCHARGED' || busy
                  ? null
                  : discharge,
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Xác nhận ra viện'),
            ),
          ],
        );
      default:
        return Container(
          padding: const EdgeInsets.all(24),
          color: const Color(0xFFF8FAFC),
          child: Text(
            '$activeTab được quản lý theo Admission ${row['admissionCode']}, không liên kết Appointment.',
            textAlign: TextAlign.center,
          ),
        );
    }
  }

  Widget patientStrip() => Container(
    padding: const EdgeInsets.all(10),
    color: const Color(0xFFEFF6FF),
    child: Wrap(
      spacing: 18,
      runSpacing: 6,
      children: [
        info('Mã BN', selected?['patientCode']),
        info('Bệnh nhân', selected?['patient']),
        info('Mã nhập viện', selected?['admissionCode']),
        info('Khoa', selected?['department']),
        info('Phòng', selected?['roomName']),
        info('Giường', selected?['bedCode']),
      ],
    ),
  );

  Widget infoBox(String label, dynamic value) => SizedBox(
    width: 260,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: Text(value?.toString() ?? ''),
    ),
  );

  Widget dropdown({
    required double width,
    required String? value,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) => SizedBox(
    width: width,
    child: DropdownButtonFormField<String>(
      initialValue: items.any((item) => item.value == value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tất cả')),
        ...items,
      ],
      onChanged: onChanged,
    ),
  );

  List<Map<String, dynamic>> get filteredRooms => rooms.where((room) {
    if (departmentId == null) return true;
    return room['departmentId'] == departmentId ||
        room['department'] ==
            departments
                .where((item) => item.id == departmentId)
                .map((item) => item.data['name'])
                .firstOrNull;
  }).toList();

  String? roomDepartmentId(dynamic roomName) {
    final room = rooms.where((item) => item['name'] == roomName).firstOrNull;
    return room?['departmentId']?.toString();
  }

  Map<String, dynamic>? bedById(dynamic id) =>
      beds.where((item) => item['id'] == id).firstOrNull;

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
      color: value == 'DISCHARGED'
          ? Colors.green.shade100
          : value == 'WAITING_BED'
          ? Colors.orange.shade100
          : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      statusText(value),
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );

  String statusText(String value) =>
      const {
        'WAITING_BED': 'Chờ giường',
        'ADMITTED': 'Đã nhập viện',
        'IN_TREATMENT': 'Đang điều trị',
        'DISCHARGED': 'Đã ra viện',
        'CANCELLED': 'Đã hủy',
      }[value] ??
      value;

  String dateTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
