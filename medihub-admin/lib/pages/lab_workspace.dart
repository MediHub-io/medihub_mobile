import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';
import '../core/admin_models.dart';

class LabWorkspace extends StatefulWidget {
  final AdminApiService service;

  const LabWorkspace({super.key, required this.service});

  @override
  State<LabWorkspace> createState() => _LabWorkspaceState();
}

class _LabWorkspaceState extends State<LabWorkspace> {
  final searchController = TextEditingController();
  final conclusionController = TextEditingController();
  final resultController = TextEditingController();
  final noteController = TextEditingController();
  final performerController = TextEditingController();
  final approverController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String? departmentId;
  String status = 'ALL';
  List<AdminRecord> departments = [];
  List<Map<String, dynamic>> orders = [];
  Map<String, dynamic>? selected;
  List<Map<String, TextEditingController>> indicatorControllers = [];
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
    searchController.dispose();
    conclusionController.dispose();
    resultController.dispose();
    noteController.dispose();
    performerController.dispose();
    approverController.dispose();
    clearIndicators();
    super.dispose();
  }

  Future<void> loadWorkspace({bool preserveSelection = true}) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final results = await Future.wait([
        widget.service.loadLabOrders(
          date: apiDate(selectedDate),
          departmentId: departmentId,
          status: status,
          search: searchController.text.trim(),
        ),
        widget.service.lookup(AdminRoute.departments),
      ]);
      final rows = results[0] as List<Map<String, dynamic>>;
      final selectedId = preserveSelection && selected != null
          ? selected!['orderItemId']
          : null;
      if (!mounted) return;
      setState(() {
        orders = rows;
        departments = results[1] as List<AdminRecord>;
        selected = rows.isEmpty
            ? null
            : rows.firstWhere(
                (item) => item['orderItemId'] == selectedId,
                orElse: () => rows.first,
              );
      });
      fillForm();
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void fillForm() {
    final result = mapOf(selected?['result']);
    conclusionController.text = result['conclusion']?.toString() ?? '';
    resultController.text = result['resultText']?.toString() ?? '';
    noteController.text = result['doctorNote']?.toString() ?? '';
    performerController.text = result['performedBy']?.toString() ?? '';
    approverController.text = result['approvedBy']?.toString() ?? '';
    clearIndicators();
    final indicators = result['indicators'] as List? ?? const [];
    for (final value in indicators) {
      addIndicator(Map<String, dynamic>.from(value as Map), rebuild: false);
    }
    if (indicatorControllers.isEmpty) addIndicator({}, rebuild: false);
    if (mounted) setState(() {});
  }

  void clearIndicators() {
    for (final row in indicatorControllers) {
      for (final controller in row.values) {
        controller.dispose();
      }
    }
    indicatorControllers = [];
  }

  void addIndicator(Map<String, dynamic> value, {bool rebuild = true}) {
    indicatorControllers.add({
      for (final key in [
        'name',
        'value',
        'unit',
        'normalMin',
        'normalMax',
        'referenceText',
      ])
        key: TextEditingController(text: value[key]?.toString() ?? ''),
    });
    if (rebuild) setState(() {});
  }

  Future<Map<String, dynamic>?> ensureResult() async {
    final row = selected;
    if (row == null) return null;
    if (row['resultId']?.toString().isNotEmpty == true) {
      return mapOf(row['result']);
    }
    final result = await widget.service.ensureLabResult(
      row['orderItemId'].toString(),
    );
    row['resultId'] = result['id'];
    row['result'] = result;
    row['status'] = result['status'];
    return result;
  }

  Future<void> runAction(
    Future<Map<String, dynamic>> Function(Map<String, dynamic>) action,
    String message,
  ) async {
    if (selected == null) return;
    setState(() => busy = true);
    try {
      final result = await ensureResult();
      if (result == null) return;
      final updated = await action(result);
      selected!['resultId'] = updated['id'];
      selected!['result'] = updated;
      selected!['status'] = updated['status'];
      fillForm();
      showMessage(message);
      await loadWorkspace();
    } catch (error) {
      showMessage(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> saveResult() => runAction((result) {
    return widget.service.saveLabResult(result['id'].toString(), {
      'resultText': resultController.text.trim(),
      'conclusion': conclusionController.text.trim(),
      'doctorNote': noteController.text.trim(),
      'performedBy': performerController.text.trim(),
      'indicators': indicatorControllers.map((row) {
        return {
          for (final entry in row.entries) entry.key: entry.value.text.trim(),
        };
      }).toList(),
    });
  }, 'Đã lưu kết quả và chuyển chờ duyệt');

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
            final left = orderList();
            final right = detail();
            if (constraints.maxWidth < 1100) {
              return Column(children: [left, const SizedBox(height: 6), right]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 48, child: left),
                const SizedBox(width: 6),
                Expanded(flex: 52, child: right),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget toolbar() {
    final current = selected?['status']?.toString();
    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            toolButton(
              'Lấy mẫu',
              Icons.colorize,
              current == 'WAITING_SAMPLE',
              () {
                runAction(
                  (result) => widget.service.takeLabSample(
                    result['id'].toString(),
                    performedBy: performerController.text.trim(),
                  ),
                  'Đã lấy mẫu',
                );
              },
            ),
            toolButton(
              'Chạy xét nghiệm',
              Icons.science_outlined,
              current == 'SAMPLE_TAKEN',
              () {
                runAction(
                  (result) => widget.service.runLabResult(
                    result['id'].toString(),
                    performedBy: performerController.text.trim(),
                  ),
                  'Đã chuyển sang chạy xét nghiệm',
                );
              },
            ),
            toolButton(
              'Nhập kết quả',
              Icons.edit_note,
              ['RUNNING', 'WAITING_APPROVAL'].contains(current),
              saveResult,
            ),
            toolButton(
              'Duyệt kết quả',
              Icons.verified_outlined,
              current == 'WAITING_APPROVAL',
              () {
                runAction(
                  (result) => widget.service.approveLabResult(
                    result['id'].toString(),
                    approvedBy: approverController.text.trim(),
                  ),
                  'Đã duyệt kết quả',
                );
              },
            ),
            toolButton(
              'In kết quả',
              Icons.print_outlined,
              current == 'APPROVED',
              () {
                showMessage('Kết quả xét nghiệm đã sẵn sàng để in');
              },
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
            width: 190,
            child: DropdownButtonFormField<String>(
              initialValue: departmentId,
              decoration: const InputDecoration(
                labelText: 'Khoa chỉ định',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả khoa')),
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
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                DropdownMenuItem(
                  value: 'WAITING_SAMPLE',
                  child: Text('Chờ lấy mẫu'),
                ),
                DropdownMenuItem(
                  value: 'SAMPLE_TAKEN',
                  child: Text('Đã lấy mẫu'),
                ),
                DropdownMenuItem(value: 'RUNNING', child: Text('Đang chạy')),
                DropdownMenuItem(
                  value: 'WAITING_APPROVAL',
                  child: Text('Chờ duyệt'),
                ),
                DropdownMenuItem(value: 'APPROVED', child: Text('Đã duyệt')),
              ],
              onChanged: (value) {
                setState(() => status = value ?? 'ALL');
                loadWorkspace(preserveSelection: false);
              },
            ),
          ),
          SizedBox(
            width: 280,
            child: TextField(
              controller: searchController,
              onSubmitted: (_) => loadWorkspace(preserveSelection: false),
              decoration: InputDecoration(
                hintText: 'Mã BN / tên / mã phiếu',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => loadWorkspace(preserveSelection: false),
                ),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget orderList() => panel(
    'Danh sách phiếu xét nghiệm',
    orders.isEmpty
        ? const SizedBox(
            height: 220,
            child: Center(child: Text('Không có phiếu chờ phù hợp')),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 46,
              columns: const [
                DataColumn(label: Text('Mã phiếu')),
                DataColumn(label: Text('Mã BN')),
                DataColumn(label: Text('Bệnh nhân')),
                DataColumn(label: Text('Xét nghiệm')),
                DataColumn(label: Text('Khoa')),
                DataColumn(label: Text('Bác sĩ')),
                DataColumn(label: Text('Thời gian')),
                DataColumn(label: Text('Trạng thái')),
              ],
              rows: orders
                  .map(
                    (item) => DataRow(
                      selected: item['orderItemId'] == selected?['orderItemId'],
                      onSelectChanged: (_) {
                        setState(() => selected = item);
                        fillForm();
                      },
                      cells: [
                        DataCell(Text(item['orderCode']?.toString() ?? '')),
                        DataCell(Text(item['patientCode']?.toString() ?? '')),
                        DataCell(Text(item['patient']?.toString() ?? '')),
                        DataCell(
                          SizedBox(
                            width: 170,
                            child: Text(item['serviceName']?.toString() ?? ''),
                          ),
                        ),
                        DataCell(Text(item['department']?.toString() ?? '')),
                        DataCell(Text(item['doctor']?.toString() ?? '')),
                        DataCell(Text(dateTime(item['orderedAt']))),
                        DataCell(statusPill(item['status']?.toString() ?? '')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
  );

  Widget detail() {
    final row = selected;
    if (row == null) {
      return panel(
        'Chi tiết kết quả',
        const SizedBox(
          height: 300,
          child: Center(child: Text('Chọn phiếu xét nghiệm')),
        ),
      );
    }
    return panel(
      'Chi tiết kết quả',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          infoStrip(row),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: field('Người thực hiện', performerController)),
              const SizedBox(width: 8),
              Expanded(child: field('Người duyệt', approverController)),
            ],
          ),
          const SizedBox(height: 8),
          indicatorTable(),
          const SizedBox(height: 8),
          field('Kết quả tổng hợp', resultController, lines: 3),
          const SizedBox(height: 8),
          field('Kết luận', conclusionController, lines: 3),
          const SizedBox(height: 8),
          field('Ghi chú bác sĩ', noteController, lines: 2),
        ],
      ),
    );
  }

  Widget indicatorTable() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Bảng chỉ số xét nghiệm',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          TextButton.icon(
            onPressed: busy ? null : () => addIndicator({}),
            icon: const Icon(Icons.add),
            label: const Text('Thêm chỉ số'),
          ),
        ],
      ),
      ...indicatorControllers.asMap().entries.map((entry) {
        final row = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(flex: 3, child: field('Chỉ số', row['name']!)),
              const SizedBox(width: 5),
              Expanded(flex: 2, child: field('Kết quả', row['value']!)),
              const SizedBox(width: 5),
              Expanded(flex: 2, child: field('Đơn vị', row['unit']!)),
              const SizedBox(width: 5),
              Expanded(flex: 2, child: field('Min', row['normalMin']!)),
              const SizedBox(width: 5),
              Expanded(flex: 2, child: field('Max', row['normalMax']!)),
              const SizedBox(width: 5),
              Expanded(
                flex: 3,
                child: field('Khoảng tham chiếu', row['referenceText']!),
              ),
              IconButton(
                onPressed: indicatorControllers.length == 1
                    ? null
                    : () {
                        for (final controller in row.values) {
                          controller.dispose();
                        }
                        setState(
                          () => indicatorControllers.removeAt(entry.key),
                        );
                      },
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        );
      }),
    ],
  );

  Widget infoStrip(Map<String, dynamic> row) => Container(
    padding: const EdgeInsets.all(10),
    color: const Color(0xFFEFF6FF),
    child: Wrap(
      spacing: 18,
      runSpacing: 6,
      children: [
        info('Mã BN', row['patientCode']),
        info('Bệnh nhân', row['patient']),
        info('Mã phiếu', row['orderCode']),
        info('Xét nghiệm', row['serviceName']),
        info('Khoa', row['department']),
        info('Bác sĩ chỉ định', row['doctor']),
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

  Widget field(
    String label,
    TextEditingController controller, {
    int lines = 1,
  }) => TextField(
    controller: controller,
    minLines: lines,
    maxLines: lines,
    enabled: selected?['status'] != 'APPROVED' && !busy,
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      border: const OutlineInputBorder(),
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

  Widget statusPill(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: value == 'APPROVED' ? Colors.green.shade100 : Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      statusText(value),
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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

  Map<String, dynamic> mapOf(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  String apiDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String dateTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    return date == null
        ? ''
        : '${displayDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String statusText(String value) =>
      const {
        'WAITING_SAMPLE': 'Chờ lấy mẫu',
        'SAMPLE_TAKEN': 'Đã lấy mẫu',
        'RUNNING': 'Đang chạy',
        'WAITING_APPROVAL': 'Chờ duyệt',
        'APPROVED': 'Đã duyệt',
        'CANCELLED': 'Đã hủy',
      }[value] ??
      value;
}
