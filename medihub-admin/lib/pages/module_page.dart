import 'dart:convert';

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';
import '../core/admin_config.dart';
import '../core/admin_models.dart';
import '../core/billing_print_helper.dart';

enum ModuleMode { list, detail, form }

class HisGridColumn {
  final String label;
  final double width;
  final String Function(AdminRecord record) value;

  const HisGridColumn(this.label, this.width, this.value);
}

class ServiceOrderCategory {
  final String label;
  final AdminRoute catalogRoute;
  final AdminRoute targetRoute;
  final String itemType;
  final IconData icon;

  const ServiceOrderCategory({
    required this.label,
    required this.catalogRoute,
    required this.targetRoute,
    required this.itemType,
    required this.icon,
  });
}

class ServiceOrderDialogResult {
  final List<Map<String, dynamic>> items;

  const ServiceOrderDialogResult(this.items);
}

class ModulePage extends StatefulWidget {
  final AdminApiService service;
  final AdminModule module;
  final ValueChanged<AdminRoute>? onRouteChanged;

  const ModulePage({
    super.key,
    required this.service,
    required this.module,
    this.onRouteChanged,
  });

  @override
  State<ModulePage> createState() => _ModulePageState();
}

class _ModulePageState extends State<ModulePage> {
  final searchController = TextEditingController();
  ModuleMode mode = ModuleMode.list;
  AdminRecord? selected;
  int page = 0;
  String statusFilter = 'ALL';
  String clinicalTab = 'DS khám';
  String? selectedLabId;
  String? selectedImagingId;
  String? selectedPrescriptionId;
  AdminRecord? calledPatient;
  Timer? searchDebounce;
  static const pageSize = 8;

  @override
  void initState() {
    super.initState();
    loadModuleData();
  }

  @override
  void didUpdateWidget(ModulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.module.route != widget.module.route) {
      page = 0;
      mode = ModuleMode.list;
      selected = null;
      statusFilter = 'ALL';
      clinicalTab = 'DS khám';
      selectedLabId = null;
      selectedImagingId = null;
      selectedPrescriptionId = null;
      calledPatient = null;
      searchController.clear();
      loadModuleData();
    }
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void loadModuleData() {
    widget.service.loadRecords(
      widget.module.route,
      search: searchController.text,
    );
    if (isVisitRoute) {
      widget.service.loadRecords(AdminRoute.queueTickets);
      widget.service.loadRecords(AdminRoute.serviceOrders);
      widget.service.loadRecords(AdminRoute.labResults);
      widget.service.loadRecords(AdminRoute.imagingResults);
      widget.service.loadRecords(AdminRoute.prescriptions);
      widget.service.loadRecords(AdminRoute.serviceUsages);
      widget.service.loadRecords(AdminRoute.payments);
      widget.service.loadRecords(AdminRoute.labServices);
      widget.service.loadRecords(AdminRoute.imagingServices);
      widget.service.loadRecords(AdminRoute.technicalServices);
      widget.service.loadRecords(AdminRoute.medicines);
      widget.service.loadRecords(AdminRoute.supplies);
      widget.service.loadRecords(AdminRoute.bedFees);
      widget.service.loadRecords(AdminRoute.examFees);
    }
  }

  void onSearchChanged(String value) {
    setState(() {
      page = 0;
      selected = null;
      selectedLabId = null;
      selectedImagingId = null;
      selectedPrescriptionId = null;
    });

    searchDebounce?.cancel();
    searchDebounce = Timer(const Duration(milliseconds: 350), loadModuleData);
  }

  List<AdminRecord> filtered() {
    final query = searchController.text.trim().toLowerCase();
    final list = widget.service.records(widget.module.route);
    return list.where((record) {
      final matchesSearch =
          query.isEmpty ||
          record.data.values.any(
            (value) => value.toString().toLowerCase().contains(query),
          );
      final status = workflowStatus(record);
      final matchesStatus = statusFilter == 'ALL' || status == statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case ModuleMode.detail:
        return detail();
      case ModuleMode.form:
        return form();
      case ModuleMode.list:
        return list();
    }
  }

  Widget list() {
    if (isWorkflowModule) {
      return workflowDesk();
    }

    final all = filtered();
    final totalPages = (all.length / pageSize).ceil().clamp(1, 9999);
    if (page >= totalPages) page = totalPages - 1;
    final rows = all.skip(page * pageSize).take(pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.service.errorMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.service.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm ${widget.module.title.toLowerCase()}',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: isParentScopedModule
                  ? null
                  : () {
                      setState(() {
                        selected = null;
                        mode = ModuleMode.form;
                      });
                    },
              icon: const Icon(Icons.add),
              label: Text(
                isParentScopedModule
                    ? 'Tạo từ lượt khám'
                    : 'Thêm ${widget.module.singular}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (widget.service.loading) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 10),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    ...widget.module.columns.map(
                      (column) => DataColumn(label: Text(labelFor(column))),
                    ),
                    const DataColumn(label: Text('Thao tác')),
                  ],
                  rows: rows.map((record) {
                    return DataRow(
                      cells: [
                        ...widget.module.columns.map(
                          (column) => DataCell(cellValue(column, record)),
                        ),
                        DataCell(actions(record)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Text('Tổng ${all.length} bản ghi'),
                    const Spacer(),
                    IconButton(
                      onPressed: page == 0
                          ? null
                          : () => setState(() {
                              page--;
                            }),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('${page + 1} / $totalPages'),
                    IconButton(
                      onPressed: page >= totalPages - 1
                          ? null
                          : () => setState(() {
                              page++;
                            }),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget actions(AdminRecord record) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isAppointmentWorkflowRoute) ...appointmentActionButtons(record),
        if (isVisitRoute) ...visitActionButtons(record),
        IconButton(
          tooltip: 'Xem chi tiết',
          onPressed: () => setState(() {
            selected = record;
            mode = ModuleMode.detail;
          }),
          icon: const Icon(Icons.visibility_outlined),
        ),
        if (widget.module.route == AdminRoute.encounters ||
            !isParentScopedModule)
          IconButton(
            tooltip: 'Sửa',
            onPressed: () => setState(() {
              selected = record;
              mode = ModuleMode.form;
            }),
            icon: const Icon(Icons.edit_outlined),
          ),
        if (widget.module.route == AdminRoute.patients ||
            widget.module.route == AdminRoute.doctors)
          IconButton(
            tooltip: 'Khóa tài khoản',
            onPressed: () async {
              await widget.service.lock(widget.module.route, record.id);
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.lock_outline),
          ),
        if (!isParentScopedModule)
          IconButton(
            tooltip: 'Xóa',
            onPressed: () async {
              await widget.service.delete(widget.module.route, record.id);
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
      ],
    );
  }

  bool get isParentScopedModule => {
    AdminRoute.encounters,
    AdminRoute.serviceOrders,
    AdminRoute.billingInvoices,
  }.contains(widget.module.route);

  List<Widget> appointmentActionButtons(AdminRecord record) {
    final status = record.data['status']?.toString() ?? '';
    return [
      if (status == 'REQUESTED')
        actionButton(
          label: 'Gửi đề xuất',
          icon: Icons.event_available_outlined,
          onPressed: () => showProposeAppointmentDialog(record),
        ),
      if (status == 'PROPOSED' || status == 'CONFIRMED')
        actionButton(
          label: 'Hủy lịch',
          icon: Icons.event_busy_outlined,
          onPressed: () => cancelAppointment(record),
          danger: true,
        ),
      if (status == 'CONFIRMED')
        actionButton(
          label: 'Tạo lượt khám',
          icon: Icons.assignment_ind_outlined,
          onPressed: () => changeAppointmentState(
            record,
            action: () => widget.service.convertAppointmentToVisit(record.id),
            message: 'Đã chuyển lịch hẹn thành lượt khám',
          ),
        ),
    ];
  }

  List<Widget> visitActionButtons(AdminRecord record) {
    final status = record.data['status']?.toString() ?? '';
    return [
      if (status == 'WAITING_RECEPTION' || status == 'RECEIVED')
        actionButton(
          label: 'Tiếp nhận',
          icon: Icons.how_to_reg_outlined,
          onPressed: () => changeAppointmentState(
            record,
            action: () => widget.service.checkInVisit(record.id),
            message: 'Đã tiếp nhận lượt khám',
          ),
        ),
      if (status == 'WAITING_EXAM')
        actionButton(
          label: 'Bắt đầu khám',
          icon: Icons.play_circle_outline,
          onPressed: () => changeAppointmentState(
            record,
            action: () => widget.service.startVisitExam(record.id),
            message: 'Đã bắt đầu phiên khám',
          ),
        ),
      if (status == 'IN_EXAM' || status == 'WAITING_PAYMENT')
        actionButton(
          label: 'Hoàn tất lượt khám',
          icon: Icons.fact_check_outlined,
          onPressed: () => changeAppointmentState(
            record,
            action: () => widget.service.completeVisit(record.id),
            message: 'Đã hoàn tất lượt khám',
          ),
        ),
      if (['WAITING_RECEPTION', 'RECEIVED', 'WAITING_EXAM'].contains(status))
        actionButton(
          label: 'Hủy lượt khám',
          icon: Icons.cancel_outlined,
          onPressed: () => changeAppointmentState(
            record,
            action: () => widget.service.cancelVisit(record.id),
            message: 'Đã hủy lượt khám',
          ),
          danger: true,
        ),
    ];
  }

  Widget actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool danger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          foregroundColor: danger
              ? Colors.red.shade700
              : const Color(0xFF007A3D),
        ),
      ),
    );
  }

  bool get isWorkflowModule {
    return {
      AdminRoute.appointments,
      AdminRoute.reception,
      AdminRoute.visits,
      AdminRoute.outpatient,
      AdminRoute.inpatient,
      AdminRoute.queueTickets,
      AdminRoute.labResults,
      AdminRoute.imagingResults,
      AdminRoute.prescriptions,
      AdminRoute.payments,
      AdminRoute.serviceUsages,
      AdminRoute.callbackRequests,
    }.contains(widget.module.route);
  }

  bool get isVisitRoute {
    return {
      AdminRoute.reception,
      AdminRoute.visits,
      AdminRoute.outpatient,
    }.contains(widget.module.route);
  }

  bool get isAppointmentWorkflowRoute {
    return widget.module.route == AdminRoute.appointments;
  }

  String workflowStatus(AdminRecord record) {
    final key =
        widget.module.route == AdminRoute.labResults ||
            widget.module.route == AdminRoute.imagingResults
        ? 'statusLabel'
        : 'status';
    return record.data[key]?.toString() ?? '';
  }

  Map<String, String> workflowStages() {
    switch (widget.module.route) {
      case AdminRoute.appointments:
        return const {
          'REQUESTED': 'Chờ đề xuất',
          'PROPOSED': 'Chờ bệnh nhân',
          'CONFIRMED': 'Đã xác nhận',
          'CONVERTED_TO_VISIT': 'Đã tạo lượt khám',
          'CHECKED_IN': 'Đã tiếp nhận',
          'IN_PROGRESS': 'Đang khám',
          'COMPLETED': 'Hoàn tất',
          'CANCELLED': 'Đã hủy',
        };
      case AdminRoute.reception:
      case AdminRoute.visits:
      case AdminRoute.outpatient:
        return const {
          'WAITING_RECEPTION': 'Chờ tiếp nhận',
          'RECEIVED': 'Đã tiếp nhận',
          'WAITING_EXAM': 'Chờ khám',
          'IN_EXAM': 'Đang khám',
          'WAITING_PAYMENT': 'Chờ thanh toán',
          'COMPLETED': 'Hoàn tất',
          'CANCELLED': 'Đã hủy',
          'ADMITTED': 'Đã nhập viện',
        };
      case AdminRoute.inpatient:
        return const {
          'ADMITTED': 'Đã nhập viện',
          'IN_TREATMENT': 'Đang điều trị',
          'DISCHARGED': 'Đã ra viện',
          'CANCELLED': 'Đã hủy',
        };
      case AdminRoute.queueTickets:
        return const {
          'WAITING': 'Đang chờ',
          'DONE': 'Đã xong',
          'CANCELLED': 'Đã hủy',
        };
      case AdminRoute.labResults:
        return const {
          'Chờ lấy mẫu': 'Chờ lấy mẫu',
          'Đã lấy mẫu': 'Đã lấy mẫu',
          'Đang chạy máy': 'Đang chạy máy',
          'Chờ duyệt': 'Chờ duyệt',
          'Đã duyệt': 'Đã duyệt',
        };
      case AdminRoute.imagingResults:
        return const {
          'Chờ thực hiện': 'Chờ thực hiện',
          'Đã chụp': 'Đã chụp',
          'Chờ đọc': 'Chờ đọc',
          'Chờ duyệt': 'Chờ duyệt',
          'Đã duyệt': 'Đã duyệt',
        };
      case AdminRoute.prescriptions:
        return const {
          'Mới': 'Chờ phát thuốc',
          'Đã phát thuốc': 'Đã phát thuốc',
        };
      case AdminRoute.payments:
        return const {
          'Chưa thanh toán': 'Chờ thanh toán',
          'Đã thanh toán': 'Đã thanh toán',
          'Đã hủy': 'Đã hủy',
        };
      case AdminRoute.serviceUsages:
        return const {
          'UNPAID': 'Chưa thu',
          'PAID': 'Đã thu',
          'CANCELLED': 'Đã hủy',
        };
      case AdminRoute.callbackRequests:
        return const {
          'PENDING': 'Chờ gọi',
          'CALLED': 'Đã gọi',
          'CANCELLED': 'Đã hủy',
        };
      default:
        return const {};
    }
  }

  Widget workflowDesk() {
    final records = filtered();
    final stages = workflowStages();
    final current =
        selected != null && records.any((item) => item.id == selected!.id)
        ? selected!
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hisCommandBar(current),
        hisClinicalTabs(current),
        if (current != null) ...[
          const SizedBox(height: 6),
          hisPatientStrip(current),
        ],
        hisStatusFilters(stages),
        const SizedBox(height: 6),
        if (widget.service.loading) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 6),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1180;
            final listPane = workflowList(records, stages, current);
            final detailPane = current == null
                ? emptyWorkflowState()
                : isVisitRoute
                ? visitTabDetail(current)
                : workflowDetail(current);
            if (!wide) {
              return Column(
                children: [listPane, const SizedBox(height: 16), detailPane],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 11, child: listPane),
                const SizedBox(width: 8),
                Expanded(flex: 10, child: detailPane),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget hisCommandBar(AdminRecord? current) {
    final canPrint = current != null;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          left: BorderSide(color: Color(0xFFBCD3EA)),
          top: BorderSide(color: Color(0xFFBCD3EA)),
          right: BorderSide(color: Color(0xFFBCD3EA)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            hisToolButton('Nhập mới', Icons.edit_outlined, () {
              setState(() {
                selected = null;
                mode = ModuleMode.form;
              });
            }),
            hisToolButton('Lưu', Icons.save_outlined, null),
            hisToolButton(
              'Xóa',
              Icons.delete_outline,
              current == null
                  ? null
                  : () async {
                      await widget.service.delete(
                        widget.module.route,
                        current.id,
                      );
                      if (!mounted) return;
                      setState(() {
                        selected = null;
                      });
                    },
            ),
            hisToolButton(
              'In phiếu',
              Icons.print_outlined,
              canPrint ? () => printCurrentRecord(current) : null,
            ),
            hisToolButton(
              'Xem phiếu',
              Icons.visibility_outlined,
              current == null
                  ? null
                  : () => setState(() {
                      selected = current;
                      mode = ModuleMode.detail;
                    }),
            ),
            hisToolButton('In khác', Icons.local_printshop_outlined, null),
            hisToolButton('Scan file', Icons.upload_file_outlined, null),
            hisToolButton('Khác', Icons.more_horiz, null),
            const SizedBox(width: 10),
            if (isVisitRoute) ...[
              hisToolButton(
                'DS Khám',
                Icons.list_alt,
                () => setState(() => clinicalTab = 'DS khám'),
              ),
              hisToolButton(
                'BA NGT',
                Icons.assignment_outlined,
                current == null
                    ? null
                    : () => setState(() => clinicalTab = 'Bệnh án'),
              ),
              hisToolButton(
                'Gọi khám',
                Icons.volume_up_outlined,
                current == null ? null : () => callPatient(current),
              ),
              hisToolButton(
                'Khám bệnh',
                Icons.medical_information_outlined,
                current == null
                    ? null
                    : () => setState(() => clinicalTab = 'Bệnh án'),
              ),
              hisToolButton(
                'Dịch vụ',
                Icons.medical_services_outlined,
                current == null
                    ? null
                    : () {
                        setState(() => clinicalTab = 'Vật tư / dịch vụ');
                        showServiceOrderSheet(current);
                      },
              ),
              hisToolButton(
                'Thuốc',
                Icons.medication_outlined,
                current == null
                    ? null
                    : () => setState(() => clinicalTab = 'Thuốc'),
              ),
              hisToolButton(
                'Next',
                Icons.skip_next_outlined,
                () => selectNextPatient(),
              ),
            ],
            if (current != null && isAppointmentWorkflowRoute)
              ...appointmentActionButtons(current),
            if (current != null && isVisitRoute) ...visitActionButtons(current),
            if (widget.module.route == AdminRoute.payments && current != null)
              hisToolButton('QR CODE', Icons.qr_code_2, null),
          ],
        ),
      ),
    );
  }

  Widget hisToolButton(String label, IconData icon, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFFBCD3EA))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: onPressed == null
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF0F172A),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: onPressed == null
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget hisClinicalTabs(AdminRecord? current) {
    if (!isVisitRoute) {
      final label = current == null
          ? 'Danh sách ${widget.module.singular}'
          : widget.module.title;
      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Color(0xFFBCD3EA)),
            right: BorderSide(color: Color(0xFFBCD3EA)),
            bottom: BorderSide(color: Color(0xFFBCD3EA)),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 32,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: const Color(0xFF0059A6),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (current == null) ...[
              const SizedBox(width: 12),
              const Text(
                'Chọn một dòng trong danh sách để xem chi tiết xử lý.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ],
        ),
      );
    }

    if (current == null) {
      final label = isVisitRoute
          ? 'Danh sách bệnh nhân'
          : 'Danh sách ${widget.module.singular}';
      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: Color(0xFFBCD3EA)),
            right: BorderSide(color: Color(0xFFBCD3EA)),
            bottom: BorderSide(color: Color(0xFFBCD3EA)),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 32,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: const Color(0xFF0059A6),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Chọn một bệnh nhân trong danh sách để mở bệnh án và các phiếu chỉ định.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      );
    }
    final tabs = [
      (AdminRoute.visits, 'DS khám', null),
      (AdminRoute.visits, 'Bệnh án', null),
      (
        AdminRoute.serviceOrders,
        'Chỉ định',
        countForRoute(AdminRoute.serviceOrders, current),
      ),
      (
        AdminRoute.labResults,
        'Xét nghiệm',
        countForRoute(AdminRoute.labResults, current),
      ),
      (
        AdminRoute.imagingResults,
        'CĐHA',
        countForRoute(AdminRoute.imagingResults, current),
      ),
      (
        AdminRoute.prescriptions,
        'Thuốc',
        countForRoute(AdminRoute.prescriptions, current),
      ),
      (
        AdminRoute.serviceUsages,
        'Vật tư / dịch vụ',
        countForRoute(AdminRoute.serviceUsages, current),
      ),
      (
        AdminRoute.payments,
        'Viện phí',
        countForRoute(AdminRoute.payments, current),
      ),
      (
        AdminRoute.callbackRequests,
        'Phiếu thu khác',
        countForRoute(AdminRoute.callbackRequests, current),
      ),
    ];
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFBCD3EA)),
          right: BorderSide(color: Color(0xFFBCD3EA)),
          bottom: BorderSide(color: Color(0xFFBCD3EA)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final route = tab.$1;
            final active = isVisitRoute
                ? clinicalTab == tab.$2
                : route == widget.module.route && tab.$2 != 'Bệnh án';
            final count = tab.$3;
            final label = count == null ? tab.$2 : '${tab.$2} ($count)';
            return InkWell(
              onTap: () {
                if (isVisitRoute) {
                  setState(() => clinicalTab = tab.$2);
                } else {
                  widget.onRouteChanged?.call(route);
                }
              },
              child: Container(
                height: 32,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF0059A6)
                      : const Color(0xFFF1F5F9),
                  border: const Border(
                    right: BorderSide(color: Color(0xFFBCD3EA)),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  int? countForRoute(AdminRoute route, AdminRecord? current) {
    if (current == null) return widget.service.records(route).length;
    return relatedRecords(route, current).length;
  }

  Widget hisPatientStrip(AdminRecord record) {
    final data = record.data;
    final parts =
        [
              data['patientCode'],
              data['patient'],
              data['fullName'],
              data['patientDob'],
              genderText(data['patientGender']),
              data['patientPhone'],
              data['department'],
            ]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .map((value) => value.toString())
            .toList();
    return Container(
      width: double.infinity,
      height: 38,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFBCD3EA)),
      ),
      child: Text(
        parts.isEmpty ? primaryTitle(record) : parts.join(' | '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget hisStatusFilters(Map<String, String> stages) {
    final allRecords = widget.service.records(widget.module.route);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFBCD3EA)),
          right: BorderSide(color: Color(0xFFBCD3EA)),
          bottom: BorderSide(color: Color(0xFFBCD3EA)),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            height: 34,
            child: TextField(
              controller: searchController,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Nhập mã BN, tên bệnh nhân, số phiếu...',
                prefixIcon: Icon(Icons.search, size: 17),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                border: OutlineInputBorder(),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          hisRadioFilter('ALL', 'Tất cả', allRecords.length),
          ...stages.entries.map((entry) {
            final count = allRecords
                .where((record) => workflowStatus(record) == entry.key)
                .length;
            return hisRadioFilter(entry.key, entry.value, count);
          }),
        ],
      ),
    );
  }

  Widget hisRadioFilter(String value, String label, int count) {
    final active = statusFilter == value;
    return InkWell(
      onTap: () => setState(() {
        statusFilter = value;
        selected = null;
        clinicalTab = 'DS khám';
        selectedLabId = null;
        selectedImagingId = null;
        selectedPrescriptionId = null;
      }),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: active ? const Color(0xFF0059A6) : const Color(0xFF64748B),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$label ($count)',
            style: TextStyle(
              color: active ? const Color(0xFF0059A6) : const Color(0xFF0F172A),
              fontSize: 12,
              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> printCurrentRecord(AdminRecord? record) async {
    if (record == null) return;
    if (widget.module.route == AdminRoute.payments) {
      openBillingCostStatement(
        data: record.data,
        organizationName: widget.service.organizationName,
      );
      return;
    }
    setState(() {
      selected = record;
      mode = ModuleMode.detail;
    });
  }

  void callPatient(AdminRecord record) {
    setState(() {
      calledPatient = record;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã gọi bệnh nhân ${record.data['patient'] ?? record.data['fullName'] ?? record.id}',
        ),
      ),
    );
  }

  void selectNextPatient() {
    final records = filtered();
    if (records.isEmpty) return;
    final currentId = selected?.id;
    final currentIndex = currentId == null
        ? -1
        : records.indexWhere((record) => record.id == currentId);
    final nextIndex = currentIndex < 0 || currentIndex >= records.length - 1
        ? 0
        : currentIndex + 1;
    setState(() {
      selected = records[nextIndex];
      clinicalTab = 'DS khám';
      selectedLabId = null;
      selectedImagingId = null;
      selectedPrescriptionId = null;
    });
    callPatient(records[nextIndex]);
  }

  Widget workflowHeader(Map<String, String> stages) {
    final allRecords = widget.service.records(widget.module.route);
    final total = allRecords.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.module.icon, color: const Color(0xFF007A3D)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.module.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$total hồ sơ đang quản lý - chọn trạng thái để lọc nhanh',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    selected = null;
                    mode = ModuleMode.form;
                  });
                },
                icon: const Icon(Icons.add),
                label: Text('Tạo ${widget.module.singular}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText:
                  'Tìm theo tên, mã bệnh nhân, số điện thoại, khoa, bác sĩ...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              statusFilterChip('ALL', 'Tất cả', allRecords.length),
              ...stages.entries.map((entry) {
                final count = allRecords
                    .where((record) => workflowStatus(record) == entry.key)
                    .length;
                return statusFilterChip(entry.key, entry.value, count);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget statusFilterChip(String value, String label, int count) {
    final active = statusFilter == value;
    return ChoiceChip(
      selected: active,
      label: Text('$label ($count)'),
      onSelected: (_) => setState(() {
        statusFilter = value;
        selected = null;
      }),
      selectedColor: const Color(0xFF007A3D),
      labelStyle: TextStyle(
        color: active ? Colors.white : const Color(0xFF334155),
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    );
  }

  Widget workflowList(
    List<AdminRecord> records,
    Map<String, String> stages,
    AdminRecord? current,
  ) {
    final showCallColumn =
        isVisitRoute || widget.module.route == AdminRoute.queueTickets;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFBCD3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hisGridTitle('Danh sách ${widget.module.singular}'),
          SizedBox(
            height: 390,
            child: records.isEmpty
                ? const Center(child: Text('Không có hồ sơ phù hợp bộ lọc.'))
                : Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          dataRowMinHeight: 30,
                          dataRowMaxHeight: 34,
                          headingRowHeight: 30,
                          columnSpacing: 18,
                          horizontalMargin: 8,
                          headingTextStyle: const TextStyle(
                            color: Color(0xFF0059A6),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                          dataTextStyle: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xFFEAF2FA),
                          ),
                          columns: [
                            const DataColumn(label: Text('STT')),
                            if (showCallColumn)
                              const DataColumn(label: Text('Gọi')),
                            ...hisWorkflowColumns().map(
                              (column) => DataColumn(label: Text(column.label)),
                            ),
                            const DataColumn(label: Text('Trạng thái')),
                            const DataColumn(label: Text('Thao tác')),
                          ],
                          rows: records.asMap().entries.map((entry) {
                            final index = entry.key;
                            final record = entry.value;
                            final selectedRow = current?.id == record.id;
                            final statusLabel =
                                stages[workflowStatus(record)] ??
                                workflowStatus(record);
                            return DataRow(
                              selected: selectedRow,
                              color: WidgetStateProperty.resolveWith((states) {
                                if (selectedRow) return const Color(0xFFFFF59D);
                                if (index.isOdd) return const Color(0xFFF6FAFE);
                                return Colors.white;
                              }),
                              onSelectChanged: (_) =>
                                  selectWorkflowRecord(record),
                              cells: [
                                DataCell(Text('${index + 1}')),
                                if (showCallColumn)
                                  DataCell(
                                    Icon(
                                      selectedRow ? Icons.flag : Icons.person,
                                      size: 16,
                                      color: selectedRow
                                          ? Colors.red
                                          : const Color(0xFF0059A6),
                                    ),
                                  ),
                                ...hisWorkflowColumns().map(
                                  (column) => DataCell(
                                    SizedBox(
                                      width: column.width,
                                      child: Text(
                                        column.value(record),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(statusPill(statusLabel)),
                                DataCell(hisRowActions(record)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFBCD3EA))),
            ),
            child: Row(
              children: [
                const Icon(Icons.refresh, size: 14, color: Color(0xFF0059A6)),
                const SizedBox(width: 8),
                Text(
                  'Tổng ${records.length} hồ sơ',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF334155),
                  ),
                ),
                const Spacer(),
                const Text(
                  '1 đến tất cả',
                  style: TextStyle(fontSize: 12, color: Color(0xFF0059A6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget hisGridTitle(String title) {
    return Container(
      height: 30,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFF0059A6),
      child: Row(
        children: [
          const Icon(Icons.table_rows, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_circle_up, color: Colors.white, size: 15),
        ],
      ),
    );
  }

  List<HisGridColumn> hisWorkflowColumns() {
    switch (widget.module.route) {
      case AdminRoute.appointments:
        return [
          HisGridColumn(
            'Mã BN',
            78,
            (r) => r.data['patientCode']?.toString() ?? '',
          ),
          HisGridColumn(
            'Họ tên',
            150,
            (r) => r.data['patient']?.toString() ?? '',
          ),
          HisGridColumn('Năm sinh', 80, (r) => birthYear(r.data['patientDob'])),
          HisGridColumn(
            'Khoa',
            130,
            (r) => r.data['department']?.toString() ?? '',
          ),
          HisGridColumn(
            'Bác sĩ',
            130,
            (r) => r.data['doctor']?.toString() ?? '',
          ),
          HisGridColumn(
            'TG hẹn',
            140,
            (r) =>
                r.data['appointmentAt']?.toString() ??
                r.data['requestedAt']?.toString() ??
                '',
          ),
        ];
      case AdminRoute.reception:
      case AdminRoute.visits:
      case AdminRoute.outpatient:
        return [
          HisGridColumn(
            'Mã lượt khám',
            105,
            (r) => r.data['visitCode']?.toString() ?? '',
          ),
          HisGridColumn(
            'Mã BN',
            78,
            (r) => r.data['patientCode']?.toString() ?? '',
          ),
          HisGridColumn(
            'Họ tên',
            150,
            (r) => r.data['patient']?.toString() ?? '',
          ),
          HisGridColumn(
            'Khoa',
            130,
            (r) => r.data['department']?.toString() ?? '',
          ),
          HisGridColumn(
            'Bác sĩ',
            130,
            (r) => r.data['doctor']?.toString() ?? '',
          ),
          HisGridColumn(
            'Tiếp nhận lúc',
            140,
            (r) => r.data['receptionTime']?.toString() ?? '',
          ),
        ];
      case AdminRoute.inpatient:
        return [
          HisGridColumn(
            'Mã vào viện',
            110,
            (r) => r.data['admissionCode']?.toString() ?? '',
          ),
          HisGridColumn(
            'Mã BN',
            86,
            (r) => r.data['patientCode']?.toString() ?? '',
          ),
          HisGridColumn(
            'Họ tên',
            150,
            (r) => r.data['patient']?.toString() ?? '',
          ),
          HisGridColumn(
            'Khoa điều trị',
            130,
            (r) => r.data['department']?.toString() ?? '',
          ),
          HisGridColumn(
            'Phòng',
            100,
            (r) => r.data['roomName']?.toString() ?? '',
          ),
          HisGridColumn(
            'Giường',
            80,
            (r) => r.data['bedCode']?.toString() ?? '',
          ),
          HisGridColumn(
            'Ngày vào viện',
            140,
            (r) => r.data['admittedAt']?.toString() ?? '',
          ),
        ];
      case AdminRoute.labResults:
        return [
          HisGridColumn(
            'Bệnh nhân',
            150,
            (r) => r.data['patient']?.toString() ?? '',
          ),
          HisGridColumn(
            'Tên xét nghiệm',
            210,
            (r) => r.data['testType']?.toString() ?? '',
          ),
          HisGridColumn(
            'TG chỉ định',
            130,
            (r) => r.data['performedAt']?.toString() ?? '',
          ),
          HisGridColumn(
            'Kết luận',
            150,
            (r) => r.data['conclusion']?.toString() ?? '',
          ),
        ];
      case AdminRoute.imagingResults:
        return [
          HisGridColumn(
            'Bệnh nhân',
            150,
            (r) => r.data['patient']?.toString() ?? '',
          ),
          HisGridColumn(
            'Tên dịch vụ',
            210,
            (r) => r.data['title']?.toString() ?? '',
          ),
          HisGridColumn(
            'Kỹ thuật',
            140,
            (r) => r.data['technique']?.toString() ?? '',
          ),
          HisGridColumn(
            'TG chỉ định',
            130,
            (r) => r.data['performedAt']?.toString() ?? '',
          ),
          HisGridColumn(
            'Bác sĩ đọc',
            130,
            (r) => r.data['doctorName']?.toString() ?? '',
          ),
        ];
      case AdminRoute.prescriptions:
        return [
          HisGridColumn(
            'Bệnh nhân',
            150,
            (r) => r.data['patient']?.toString() ?? '',
          ),
          HisGridColumn(
            'Bác sĩ',
            140,
            (r) => r.data['doctor']?.toString() ?? '',
          ),
          HisGridColumn(
            'Ngày kê',
            120,
            (r) => r.data['prescribedAt']?.toString() ?? '',
          ),
          HisGridColumn(
            'Thuốc',
            260,
            (r) => r.data['medicines']?.toString().replaceAll('\n', '; ') ?? '',
          ),
        ];
      case AdminRoute.payments:
        return [
          HisGridColumn(
            'Mã BN',
            78,
            (r) => r.data['patientCode']?.toString() ?? '',
          ),
          HisGridColumn(
            'Bệnh nhân',
            150,
            (r) => r.data['patient']?.toString() ?? '',
          ),
          HisGridColumn(
            'Ngày',
            120,
            (r) => r.data['createdAt']?.toString() ?? '',
          ),
          HisGridColumn(
            'Tổng tiền',
            110,
            (r) => r.data['amount']?.toString() ?? '',
          ),
          HisGridColumn(
            'BHYT trả',
            110,
            (r) => r.data['insurancePaidText']?.toString() ?? '',
          ),
          HisGridColumn(
            'BN trả',
            110,
            (r) => r.data['patientPaidText']?.toString() ?? '',
          ),
        ];
      case AdminRoute.serviceUsages:
        return [
          HisGridColumn(
            'Bệnh nhân',
            150,
            (r) => r.data['patient']?.toString() ?? '',
          ),
          HisGridColumn(
            'Tên dịch vụ',
            220,
            (r) => r.data['itemName']?.toString() ?? '',
          ),
          HisGridColumn('SL', 60, (r) => r.data['quantity']?.toString() ?? ''),
          HisGridColumn(
            'Thành tiền',
            110,
            (r) => r.data['amount']?.toString() ?? '',
          ),
          HisGridColumn('Ngày', 120, (r) => r.data['usedAt']?.toString() ?? ''),
        ];
      default:
        return [
          HisGridColumn('Bệnh nhân', 150, (r) => primaryTitle(r)),
          HisGridColumn('Nội dung', 240, (r) => secondaryTitle(r)),
          HisGridColumn(
            'Ngày',
            120,
            (r) =>
                r.data['createdAt']?.toString() ??
                r.data['performedAt']?.toString() ??
                '',
          ),
        ];
    }
  }

  Widget hisRowActions(AdminRecord record) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Chọn',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          onPressed: () => selectWorkflowRecord(record),
          icon: const Icon(
            Icons.check_box_outlined,
            size: 17,
            color: Color(0xFF0059A6),
          ),
        ),
        IconButton(
          tooltip: 'Xem',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          onPressed: () => setState(() {
            selected = record;
            mode = ModuleMode.detail;
          }),
          icon: const Icon(Icons.visibility_outlined, size: 17),
        ),
        IconButton(
          tooltip: 'Sửa',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          onPressed: () => setState(() {
            selected = record;
            mode = ModuleMode.form;
          }),
          icon: const Icon(Icons.edit_outlined, size: 17),
        ),
        IconButton(
          tooltip: 'Xóa',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          onPressed: () async {
            await widget.service.delete(widget.module.route, record.id);
            if (!mounted) return;
            setState(() {
              if (selected?.id == record.id) selected = null;
            });
          },
          icon: const Icon(Icons.delete_outline, size: 17, color: Colors.red),
        ),
      ],
    );
  }

  void selectWorkflowRecord(AdminRecord record) {
    setState(() {
      selected = record;
      selectedLabId = null;
      selectedImagingId = null;
      selectedPrescriptionId = null;
    });
  }

  String birthYear(dynamic value) {
    final text = value?.toString() ?? '';
    final match = RegExp(r'(\d{4})').firstMatch(text);
    return match?.group(1) ?? text;
  }

  Widget workflowRecordCard(
    AdminRecord record, {
    required bool selected,
    required String statusLabel,
  }) {
    final data = record.data;
    final title = primaryTitle(record);
    final subtitle = secondaryTitle(record);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => selectWorkflowRecord(record),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF1F8F3) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF007A3D)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  statusPill(statusLabel),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              if ((data['appointmentAt'] ??
                      data['performedAt'] ??
                      data['createdAt'] ??
                      '')
                  .toString()
                  .isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        (data['appointmentAt'] ??
                                data['performedAt'] ??
                                data['createdAt'] ??
                                '')
                            .toString(),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget statusPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF007A3D),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  String primaryTitle(AdminRecord record) {
    final data = record.data;
    switch (widget.module.route) {
      case AdminRoute.appointments:
      case AdminRoute.reception:
      case AdminRoute.visits:
      case AdminRoute.outpatient:
      case AdminRoute.inpatient:
      case AdminRoute.queueTickets:
      case AdminRoute.labResults:
      case AdminRoute.imagingResults:
      case AdminRoute.prescriptions:
      case AdminRoute.payments:
      case AdminRoute.serviceUsages:
      case AdminRoute.callbackRequests:
        final candidates =
            [
                  data['patient'],
                  data['fullName'],
                  data['patientCode'],
                  data['phone'],
                ]
                .where(
                  (value) =>
                      value != null && value.toString().trim().isNotEmpty,
                )
                .map((value) => value.toString())
                .toList();
        return candidates.isEmpty ? 'Chưa có bệnh nhân' : candidates.first;
      default:
        return data['title']?.toString() ?? record.id;
    }
  }

  String secondaryTitle(AdminRecord record) {
    final data = record.data;
    switch (widget.module.route) {
      case AdminRoute.appointments:
      case AdminRoute.reception:
      case AdminRoute.visits:
      case AdminRoute.outpatient:
      case AdminRoute.inpatient:
        return [data['department'], data['doctor'], data['note']]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .join(' - ');
      case AdminRoute.queueTickets:
        return '${data['ticketNumber'] ?? ''} - ${data['department'] ?? ''} ${data['roomName'] ?? ''}';
      case AdminRoute.labResults:
        return '${data['testType'] ?? ''} - ${data['conclusion'] ?? ''}';
      case AdminRoute.imagingResults:
        return '${data['title'] ?? ''} - ${data['technique'] ?? ''}';
      case AdminRoute.prescriptions:
        return '${data['doctor'] ?? ''} - ${data['medicines'] ?? ''}';
      case AdminRoute.payments:
      case AdminRoute.serviceUsages:
        return '${data['amount'] ?? ''} - ${data['note'] ?? data['itemName'] ?? ''}';
      case AdminRoute.callbackRequests:
        return '${data['phone'] ?? ''} - ${data['note'] ?? ''}';
      default:
        return '';
    }
  }

  Widget visitTabDetail(AdminRecord record) {
    switch (clinicalTab) {
      case 'DS khám':
        return queueVisitPanel(record);
      case 'Chỉ định':
        return visitRelatedPanel(
          record: record,
          title: 'Phiếu chỉ định dịch vụ',
          route: AdminRoute.serviceOrders,
          icon: Icons.medical_services_outlined,
          emptyText: 'Chưa có phiếu chỉ định cho lượt khám này.',
          actionLabel: 'Tạo phiếu chỉ định',
          onCreate: () => showServiceOrderSheet(record),
          subtitle: (item) =>
              '${item.data['orderCode'] ?? ''} - ${item.data['orderType'] ?? ''} - ${item.data['status'] ?? ''}',
        );
      case 'Xét nghiệm':
        return labVisitPanel(record);
      case 'CĐHA':
        return imagingVisitPanel(record);
      case 'Thuốc':
        return prescriptionVisitPanel(record);
      case 'Vật tư / dịch vụ':
        return serviceUsageVisitPanel(record);
      case 'Viện phí':
        return visitRelatedPanel(
          record: record,
          title: 'Viện phí',
          route: AdminRoute.payments,
          icon: Icons.payments_outlined,
          emptyText: 'Chưa có phiếu viện phí cho lượt khám này.',
          actionLabel: 'Tạo khoản thu',
          onCreate: () => createBilling(record),
          subtitle: (item) =>
              '${item.data['amount'] ?? ''} - ${item.data['status'] ?? ''}',
        );
      case 'Phiếu thu khác':
        return visitRelatedPanel(
          record: record,
          title: 'Phiếu thu khác',
          route: AdminRoute.callbackRequests,
          icon: Icons.receipt_long_outlined,
          emptyText: 'Chưa có phiếu thu khác.',
          actionLabel: null,
          onCreate: null,
          subtitle: (item) =>
              '${item.data['phone'] ?? ''} - ${item.data['status'] ?? ''}',
        );
      case 'Bệnh án':
      default:
        return medicalRecordVisitPanel(record);
    }
  }

  Widget queueVisitPanel(AdminRecord record) {
    final data = record.data;
    final department =
        data['department']?.toString().trim().toLowerCase() ?? '';
    final tickets = widget.service.records(AdminRoute.queueTickets).where((
      ticket,
    ) {
      final ticketDepartment =
          ticket.data['department']?.toString().trim().toLowerCase() ?? '';
      if (department.isEmpty) return true;
      return ticketDepartment == department ||
          ticketDepartment.contains(department);
    }).toList();

    return panel(
      title: 'DS Khám theo chuyên khoa',
      actions: [
        ElevatedButton.icon(
          onPressed: () => callPatient(record),
          icon: const Icon(Icons.volume_up_outlined),
          label: const Text('Gọi bệnh nhân'),
        ),
        ElevatedButton.icon(
          onPressed: selectNextPatient,
          icon: const Icon(Icons.skip_next_outlined),
          label: const Text('Next'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hisPatientStrip(record),
          const SizedBox(height: 10),
          patientCallDisplay(record),
          const SizedBox(height: 10),
          if (tickets.isEmpty)
            const Text(
              'Chưa có bệnh nhân lấy số thứ tự trong chuyên khoa này.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFEAF2FA),
                ),
                columns: const [
                  DataColumn(label: Text('STT')),
                  DataColumn(label: Text('Số TT')),
                  DataColumn(label: Text('Bệnh nhân')),
                  DataColumn(label: Text('Khoa')),
                  DataColumn(label: Text('Phòng')),
                  DataColumn(label: Text('Trạng thái')),
                ],
                rows: tickets.asMap().entries.map((entry) {
                  final ticket = entry.value;
                  return DataRow(
                    color: WidgetStateProperty.all(
                      ticket.data['patient'] == data['patient']
                          ? const Color(0xFFFFF59D)
                          : null,
                    ),
                    cells: [
                      DataCell(Text('${entry.key + 1}')),
                      DataCell(
                        Text(ticket.data['ticketNumber']?.toString() ?? ''),
                      ),
                      DataCell(Text(ticket.data['patient']?.toString() ?? '')),
                      DataCell(
                        Text(ticket.data['department']?.toString() ?? ''),
                      ),
                      DataCell(Text(ticket.data['roomName']?.toString() ?? '')),
                      DataCell(
                        statusPill(ticket.data['status']?.toString() ?? ''),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget patientCallDisplay(AdminRecord record) {
    final active = calledPatient ?? record;
    final next = nextRecordAfter(active);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FA),
        border: Border.all(color: const Color(0xFFBCD3EA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_outlined,
            color: Color(0xFF0059A6),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Màn hình gọi bệnh nhân',
                  style: TextStyle(
                    color: Color(0xFF0059A6),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đang gọi: ${active.data['patient'] ?? active.data['fullName'] ?? active.id}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  'Tiếp theo: ${next == null ? 'Chưa có' : next.data['patient'] ?? next.data['fullName'] ?? next.id}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: selectNextPatient,
            icon: const Icon(Icons.skip_next_outlined),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  AdminRecord? nextRecordAfter(AdminRecord record) {
    final records = filtered();
    if (records.isEmpty) return null;
    final index = records.indexWhere((item) => item.id == record.id);
    if (index < 0 || index >= records.length - 1) return records.first;
    return records[index + 1];
  }

  Widget medicalRecordVisitPanel(AdminRecord record) {
    final data = record.data;
    final vitals = {
      'Mạch (lần/phút)': data['pulse'] ?? '80',
      'Nhiệt độ (°C)': data['temperature'] ?? '37',
      'Huyết áp (mmHg)': data['bloodPressure'] ?? '120 / 70',
      'Nhịp thở (lần/phút)': data['respirationRate'] ?? '20',
      'Cân nặng (kg)': data['weight'] ?? '50',
      'Chiều cao (cm)': data['height'] ?? '',
      'BMI(kg/m2)': data['bmi'] ?? '0.00',
      'SpO2': data['spo2'] ?? '',
    };

    return panel(
      title: 'Bệnh án ngoại trú',
      actions: [
        ...visitActionButtons(record),
        OutlinedButton.icon(
          onPressed: () => showOrderPrintPreview(
            record,
            relatedRecords(AdminRoute.labResults, record),
            relatedRecords(AdminRoute.imagingResults, record),
            relatedRecords(AdminRoute.serviceUsages, record),
          ),
          icon: const Icon(Icons.print_outlined),
          label: const Text('In bệnh án'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hisPatientStrip(record),
          const SizedBox(height: 10),
          medicalRecordSection('Thông tin bệnh nhân', [
            medicalReadonlyField(
              'Mã tiếp nhận',
              data['encounterCode'] ?? record.id,
              width: 190,
            ),
            medicalReadonlyField('TT Bệnh nhân', data['patient'], width: 230),
            medicalReadonlyField(
              'Địa chỉ',
              data['patientAddress'] ?? data['address'],
              width: 300,
            ),
            medicalReadonlyField('Thẻ BHYT', data['insuranceNo'], width: 220),
            medicalReadonlyField(
              'Yêu cầu khám',
              data['department'],
              width: 220,
            ),
            medicalReadonlyField('Bác sĩ', data['doctor'], width: 220),
            medicalReadonlyField(
              'Trạng thái',
              statusText(data['status']),
              width: 180,
            ),
          ]),
          const SizedBox(height: 10),
          medicalRecordSection('Thông tin khám bệnh', [
            medicalReadonlyField(
              'Lý do vào viện',
              data['note'],
              width: 480,
              lines: 3,
            ),
            medicalReadonlyField(
              'Quá trình bệnh lý',
              data['pathologicalProcess'] ?? data['note'],
              width: 480,
              lines: 3,
            ),
            medicalReadonlyField(
              'Tiền sử - Bản thân',
              data['personalHistory'],
              width: 480,
              lines: 3,
            ),
            medicalReadonlyField(
              'Tiền sử - Gia đình',
              data['familyHistory'],
              width: 480,
              lines: 3,
            ),
            medicalReadonlyField(
              'Khám toàn thân',
              data['generalExam'] ?? 'Bệnh nhân tỉnh\nDa niêm mạc hồng',
              width: 480,
              lines: 3,
            ),
            medicalReadonlyField(
              'Khám bộ phận',
              data['specializedExam'] ??
                  'Tim T1, T2 rõ\nPhổi thông khí rõ\nBụng mềm',
              width: 480,
              lines: 3,
            ),
            ...vitals.entries.map(
              (entry) =>
                  medicalReadonlyField(entry.key, entry.value, width: 230),
            ),
            medicalReadonlyField(
              'Kết quả CLS',
              clinicalSummary(record),
              width: 480,
              lines: 3,
            ),
            medicalReadonlyField(
              'Chẩn đoán ban đầu',
              data['diagnosis'] ?? data['note'],
              width: 480,
              lines: 2,
            ),
            medicalReadonlyField(
              'Hướng xử lý',
              data['treatmentNote'],
              width: 980,
              lines: 3,
            ),
            medicalReadonlyField(
              'Bệnh chính',
              data['diagnosisCode'] ?? 'R51 - Đau đầu',
              width: 480,
            ),
            medicalReadonlyField(
              'Bệnh kèm theo',
              data['secondaryDiagnosis'],
              width: 480,
            ),
            medicalReadonlyField(
              'Khác',
              data['conclusion'],
              width: 980,
              lines: 3,
            ),
          ]),
        ],
      ),
    );
  }

  Widget medicalRecordSection(String title, List<Widget> children) {
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: const Color(0xFFE5E7EB),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(spacing: 8, runSpacing: 8, children: children),
          ),
        ],
      ),
    );
  }

  Widget medicalReadonlyField(
    String label,
    dynamic value, {
    double width = 240,
    int lines = 1,
  }) {
    final text = value?.toString().trim() ?? '';
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Container(
            height: lines == 1 ? 26 : (lines * 34).toDouble(),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDED),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(
              text.isEmpty ? '' : text,
              maxLines: lines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  String clinicalSummary(AdminRecord record) {
    final labs = relatedRecords(AdminRoute.labResults, record).length;
    final imaging = relatedRecords(AdminRoute.imagingResults, record).length;
    final prescriptions = relatedRecords(
      AdminRoute.prescriptions,
      record,
    ).length;
    final usages = relatedRecords(AdminRoute.serviceUsages, record).length;
    final parts = [
      if (labs > 0) '$labs phiếu xét nghiệm',
      if (imaging > 0) '$imaging phiếu CĐHA',
      if (prescriptions > 0) '$prescriptions đơn thuốc',
      if (usages > 0) '$usages dịch vụ/vật tư',
    ];
    return parts.isEmpty ? 'Chưa có kết quả cận lâm sàng.' : parts.join('\n');
  }

  Widget labVisitPanel(AdminRecord record) {
    final labs = relatedRecords(AdminRoute.labResults, record);
    final active = selectedRelatedRecord(labs, selectedLabId);
    final places = uniqueLabels(labs.map((item) => servicePlace(item, record)));

    return panel(
      title: 'Xét nghiệm',
      actions: [
        ElevatedButton.icon(
          onPressed: record.data['status'] == 'IN_EXAM'
              ? () => showServiceOrderSheet(record)
              : null,
          icon: const Icon(Icons.science_outlined),
          label: const Text('Tạo phiếu xét nghiệm'),
        ),
        OutlinedButton.icon(
          onPressed: () => showOrderPrintPreview(
            record,
            labs,
            relatedRecords(AdminRoute.imagingResults, record),
            relatedRecords(AdminRoute.serviceUsages, record),
          ),
          icon: const Icon(Icons.print_outlined),
          label: const Text('In phiếu'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hisPatientStrip(record),
          const SizedBox(height: 8),
          if (places.isNotEmpty)
            hisPlaceSelector(
              places: places,
              activePlace: active == null
                  ? places.first
                  : servicePlace(active, record),
              onSelect: (place) {
                final match = labs.where(
                  (item) => servicePlace(item, record) == place,
                );
                if (match.isEmpty) return;
                setState(() => selectedLabId = match.first.id);
              },
            ),
          const SizedBox(height: 8),
          hisDataBlock(
            title: 'Danh sách xét nghiệm',
            child: labs.isEmpty
                ? emptyHisBox('Chưa có chỉ định xét nghiệm cho bệnh nhân này.')
                : horizontalTable(
                    DataTable(
                      dataRowMinHeight: 30,
                      dataRowMaxHeight: 34,
                      headingRowHeight: 30,
                      columnSpacing: 18,
                      horizontalMargin: 8,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFEAF2FA),
                      ),
                      columns: const [
                        DataColumn(label: Text('Barcode')),
                        DataColumn(label: Text('Số phiếu')),
                        DataColumn(label: Text('Phiếu điều trị')),
                        DataColumn(label: Text('Bác sĩ chỉ định')),
                        DataColumn(label: Text('TG chỉ định')),
                        DataColumn(label: Text('TG trả KQ')),
                        DataColumn(label: Text('Nơi thực hiện')),
                        DataColumn(label: Text('Trạng thái')),
                      ],
                      rows: labs.map((item) {
                        final selected = active?.id == item.id;
                        return DataRow(
                          selected: selected,
                          color: hisSelectedRowColor(selected),
                          onSelectChanged: (_) =>
                              setState(() => selectedLabId = item.id),
                          cells: [
                            DataCell(Text(shortCode(item, 'XN'))),
                            DataCell(
                              Text(item.data['orderId']?.toString() ?? ''),
                            ),
                            DataCell(
                              Text(item.data['encounterId']?.toString() ?? ''),
                            ),
                            DataCell(
                              Text(
                                item.data['doctorName']?.toString() ??
                                    record.data['doctor']?.toString() ??
                                    '',
                              ),
                            ),
                            DataCell(
                              Text(item.data['performedAt']?.toString() ?? ''),
                            ),
                            DataCell(
                              Text(
                                item.data['resultedAt']?.toString() ??
                                    item.data['performedAt']?.toString() ??
                                    '',
                              ),
                            ),
                            DataCell(Text(servicePlace(item, record))),
                            DataCell(
                              statusPill(
                                item.data['statusLabel']?.toString() ?? '',
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          hisDataBlock(
            title: 'Danh sách dịch vụ chỉ định',
            child: active == null
                ? emptyHisBox('Chọn một phiếu xét nghiệm để xem dịch vụ.')
                : labServiceTable(active),
          ),
          const SizedBox(height: 8),
          hisDataBlock(
            title: 'Danh sách kết quả xét nghiệm',
            child: active == null
                ? emptyHisBox('Chọn một phiếu xét nghiệm để xem kết quả.')
                : labResultTable(active),
          ),
        ],
      ),
    );
  }

  Widget labServiceTable(AdminRecord lab) {
    final indicators = mapList(lab.data['indicators']);
    final rows = indicators.isEmpty
        ? [
            {
              'code': shortCode(lab, 'XN'),
              'name': lab.data['testType']?.toString() ?? '',
              'status': lab.data['statusLabel']?.toString() ?? '',
              'note': lab.data['doctorNote']?.toString() ?? '',
            },
          ]
        : indicators.map((item) {
            return {
              'code': item['code']?.toString() ?? shortCode(lab, 'XN'),
              'name': item['name']?.toString() ?? '',
              'status': lab.data['statusLabel']?.toString() ?? '',
              'note': lab.data['doctorNote']?.toString() ?? '',
            };
          }).toList();

    return horizontalTable(
      DataTable(
        dataRowMinHeight: 30,
        dataRowMaxHeight: 44,
        headingRowHeight: 30,
        columnSpacing: 18,
        horizontalMargin: 8,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFEAF2FA)),
        columns: const [
          DataColumn(label: Text('Mã xét nghiệm')),
          DataColumn(label: Text('Tên xét nghiệm')),
          DataColumn(label: Text('Loại thanh toán')),
          DataColumn(label: Text('Số lượng')),
          DataColumn(label: Text('Trạng thái')),
          DataColumn(label: Text('Ghi chú')),
        ],
        rows: rows.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item['code']?.toString() ?? '')),
              DataCell(
                SizedBox(
                  width: 260,
                  child: Text(item['name']?.toString() ?? ''),
                ),
              ),
              const DataCell(Text('VIỆN PHÍ')),
              const DataCell(Text('1')),
              DataCell(Text(item['status']?.toString() ?? '')),
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(item['note']?.toString() ?? ''),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget labResultTable(AdminRecord lab) {
    final indicators = mapList(lab.data['indicators']);
    if (indicators.isEmpty) {
      return emptyHisBox('Phiếu này chưa có chỉ số kết quả.');
    }
    return horizontalTable(
      DataTable(
        dataRowMinHeight: 30,
        dataRowMaxHeight: 38,
        headingRowHeight: 30,
        columnSpacing: 18,
        horizontalMargin: 8,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFEAF2FA)),
        columns: const [
          DataColumn(label: Text('Mã xét nghiệm')),
          DataColumn(label: Text('Tên xét nghiệm')),
          DataColumn(label: Text('Kết quả')),
          DataColumn(label: Text('Trị số bình thường')),
          DataColumn(label: Text('TG thực hiện')),
          DataColumn(label: Text('TG trả KQ')),
          DataColumn(label: Text('Người trả kết quả')),
        ],
        rows: indicators.map((item) {
          final abnormal = labIndicatorAbnormal(item);
          return DataRow(
            color: WidgetStateProperty.all(
              abnormal ? const Color(0xFFFFF1F2) : null,
            ),
            cells: [
              DataCell(Text(item['code']?.toString() ?? shortCode(lab, 'XN'))),
              DataCell(
                SizedBox(
                  width: 260,
                  child: Text(
                    item['name']?.toString() ?? '',
                    style: TextStyle(
                      color: abnormal
                          ? Colors.red.shade700
                          : const Color(0xFF0F172A),
                      fontWeight: abnormal ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${item['value'] ?? ''} ${item['unit'] ?? ''}',
                  style: TextStyle(
                    color: abnormal
                        ? Colors.red.shade700
                        : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DataCell(Text(labIndicatorRange(item))),
              DataCell(Text(lab.data['performedAt']?.toString() ?? '')),
              DataCell(
                Text(
                  lab.data['resultedAt']?.toString() ??
                      lab.data['performedAt']?.toString() ??
                      '',
                ),
              ),
              DataCell(
                Text(
                  lab.data['resultedBy']?.toString() ??
                      lab.data['doctorName']?.toString() ??
                      '',
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget imagingVisitPanel(AdminRecord record) {
    final imaging = relatedRecords(AdminRoute.imagingResults, record);
    final active = selectedRelatedRecord(imaging, selectedImagingId);
    final places = uniqueLabels(
      imaging.map((item) => servicePlace(item, record)),
    );

    return panel(
      title: 'Chẩn đoán hình ảnh',
      actions: [
        ElevatedButton.icon(
          onPressed: record.data['status'] == 'IN_EXAM'
              ? () => showServiceOrderSheet(record)
              : null,
          icon: const Icon(Icons.image_search_outlined),
          label: const Text('Tạo phiếu CĐHA'),
        ),
        OutlinedButton.icon(
          onPressed: active == null
              ? null
              : () => showDicomViewerDialog(active),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Xem ảnh DICOM'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hisPatientStrip(record),
          const SizedBox(height: 8),
          if (places.isNotEmpty)
            hisPlaceSelector(
              places: places,
              activePlace: active == null
                  ? places.first
                  : servicePlace(active, record),
              onSelect: (place) {
                final match = imaging.where(
                  (item) => servicePlace(item, record) == place,
                );
                if (match.isEmpty) return;
                setState(() => selectedImagingId = match.first.id);
              },
            ),
          const SizedBox(height: 8),
          hisDataBlock(
            title: 'Danh sách chẩn đoán hình ảnh',
            child: imaging.isEmpty
                ? emptyHisBox('Chưa có chỉ định CĐHA cho bệnh nhân này.')
                : horizontalTable(
                    DataTable(
                      dataRowMinHeight: 30,
                      dataRowMaxHeight: 34,
                      headingRowHeight: 30,
                      columnSpacing: 18,
                      horizontalMargin: 8,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFEAF2FA),
                      ),
                      columns: const [
                        DataColumn(label: Text('Số phiếu')),
                        DataColumn(label: Text('Phiếu điều trị')),
                        DataColumn(label: Text('Bác sĩ chỉ định')),
                        DataColumn(label: Text('Thời gian chỉ định')),
                        DataColumn(label: Text('P. thực hiện')),
                        DataColumn(label: Text('Phòng')),
                        DataColumn(label: Text('Khẩn')),
                      ],
                      rows: imaging.map((item) {
                        final selected = active?.id == item.id;
                        return DataRow(
                          selected: selected,
                          color: hisSelectedRowColor(selected),
                          onSelectChanged: (_) =>
                              setState(() => selectedImagingId = item.id),
                          cells: [
                            DataCell(
                              Text(
                                item.data['orderId']?.toString() ??
                                    shortCode(item, 'CDHA'),
                              ),
                            ),
                            DataCell(
                              Text(item.data['encounterId']?.toString() ?? ''),
                            ),
                            DataCell(
                              Text(
                                item.data['doctorName']?.toString() ??
                                    record.data['doctor']?.toString() ??
                                    '',
                              ),
                            ),
                            DataCell(
                              Text(item.data['performedAt']?.toString() ?? ''),
                            ),
                            DataCell(Text(servicePlace(item, record))),
                            DataCell(
                              Text(item.data['roomName']?.toString() ?? ''),
                            ),
                            DataCell(
                              Text(
                                item.data['urgent'] == true
                                    ? 'Khẩn'
                                    : 'Bình thường',
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          hisDataBlock(
            title: 'Danh sách kết quả chẩn đoán hình ảnh',
            child: active == null
                ? emptyHisBox('Chọn một phiếu CĐHA để xem kết quả.')
                : imagingResultTable(active),
          ),
        ],
      ),
    );
  }

  Widget imagingResultTable(AdminRecord item) {
    return horizontalTable(
      DataTable(
        dataRowMinHeight: 34,
        dataRowMaxHeight: 52,
        headingRowHeight: 30,
        columnSpacing: 18,
        horizontalMargin: 8,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFEAF2FA)),
        columns: const [
          DataColumn(label: Text('ICON')),
          DataColumn(label: Text('Mã DV')),
          DataColumn(label: Text('Tên dịch vụ')),
          DataColumn(label: Text('Loại thanh toán')),
          DataColumn(label: Text('Số lượng')),
          DataColumn(label: Text('Trạng thái')),
          DataColumn(label: Text('Kết luận')),
        ],
        rows: [
          DataRow(
            color: WidgetStateProperty.all(const Color(0xFFFFF59D)),
            cells: [
              const DataCell(
                Icon(
                  Icons.workspace_premium_outlined,
                  size: 16,
                  color: Color(0xFFD97706),
                ),
              ),
              DataCell(Text(shortCode(item, 'CDHA'))),
              DataCell(
                SizedBox(
                  width: 280,
                  child: Text(item.data['title']?.toString() ?? ''),
                ),
              ),
              const DataCell(Text('VIỆN PHÍ')),
              const DataCell(Text('1')),
              DataCell(Text(item.data['statusLabel']?.toString() ?? '')),
              DataCell(
                SizedBox(
                  width: 360,
                  child: Text(item.data['conclusion']?.toString() ?? ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> showDicomViewerDialog(AdminRecord item) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xem ảnh DICOM'),
        content: SizedBox(
          width: 720,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.data['title']?.toString() ?? 'Chẩn đoán hình ảnh',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              imagingPreview(item.data['imageUrl']?.toString() ?? ''),
              const SizedBox(height: 12),
              Text(item.data['conclusion']?.toString() ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget prescriptionVisitPanel(AdminRecord record) {
    final prescriptions = relatedRecords(AdminRoute.prescriptions, record);
    final active = selectedRelatedRecord(prescriptions, selectedPrescriptionId);

    return panel(
      title: 'Thuốc',
      actions: [
        ElevatedButton.icon(
          onPressed: record.data['status'] == 'IN_EXAM'
              ? () => createPrescription(record)
              : null,
          icon: const Icon(Icons.medication_outlined),
          label: const Text('Kê đơn thuốc'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hisPatientStrip(record),
          const SizedBox(height: 8),
          hisDataBlock(
            title: 'Danh sách phiếu thuốc',
            child: prescriptions.isEmpty
                ? emptyHisBox('Chưa có đơn thuốc cho lượt khám này.')
                : horizontalTable(
                    DataTable(
                      dataRowMinHeight: 30,
                      dataRowMaxHeight: 34,
                      headingRowHeight: 30,
                      columnSpacing: 18,
                      horizontalMargin: 8,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFEAF2FA),
                      ),
                      columns: const [
                        DataColumn(label: Text('Số phiếu')),
                        DataColumn(label: Text('Phiếu ĐTRI')),
                        DataColumn(label: Text('Người chỉ định')),
                        DataColumn(label: Text('Phòng')),
                        DataColumn(label: Text('Ngày chỉ định')),
                        DataColumn(label: Text('Ngày sử dụng')),
                        DataColumn(label: Text('Kho')),
                        DataColumn(label: Text('STT')),
                        DataColumn(label: Text('Loại phiếu')),
                      ],
                      rows: prescriptions.asMap().entries.map((entry) {
                        final item = entry.value;
                        final selected = active?.id == item.id;
                        return DataRow(
                          selected: selected,
                          color: hisSelectedRowColor(selected),
                          onSelectChanged: (_) =>
                              setState(() => selectedPrescriptionId = item.id),
                          cells: [
                            DataCell(
                              Text(
                                item.data['orderId']?.toString() ??
                                    shortCode(item, 'BV'),
                              ),
                            ),
                            DataCell(
                              Text(item.data['encounterId']?.toString() ?? ''),
                            ),
                            DataCell(
                              Text(
                                item.data['doctor']?.toString() ??
                                    record.data['doctor']?.toString() ??
                                    '',
                              ),
                            ),
                            DataCell(
                              Text(
                                item.data['department']?.toString() ??
                                    record.data['department']?.toString() ??
                                    '',
                              ),
                            ),
                            DataCell(
                              Text(item.data['prescribedAt']?.toString() ?? ''),
                            ),
                            DataCell(
                              Text(
                                item.data['usedAt']?.toString() ??
                                    item.data['prescribedAt']?.toString() ??
                                    '',
                              ),
                            ),
                            DataCell(
                              Text(
                                item.data['warehouse']?.toString() ??
                                    'Mua ngoài',
                              ),
                            ),
                            DataCell(Text('${entry.key + 1}')),
                            DataCell(
                              Text(item.data['type']?.toString() ?? 'Nhận'),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          hisDataBlock(
            title: 'Danh sách chi tiết phiếu thuốc',
            child: active == null
                ? emptyHisBox('Chọn một phiếu thuốc để xem chi tiết.')
                : prescriptionItemsTable(active),
          ),
        ],
      ),
    );
  }

  Widget prescriptionItemsTable(AdminRecord prescription) {
    final items = mapList(prescription.data['items']);
    final rows = items.isEmpty
        ? (prescription.data['medicines']?.toString() ?? '')
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .map((line) => {'medicineName': line.trim(), 'quantity': '1'})
              .toList()
        : items;
    if (rows.isEmpty) {
      return emptyHisBox('Đơn thuốc chưa có dòng thuốc.');
    }
    return horizontalTable(
      DataTable(
        dataRowMinHeight: 34,
        dataRowMaxHeight: 64,
        headingRowHeight: 30,
        columnSpacing: 18,
        horizontalMargin: 8,
        headingRowColor: WidgetStateProperty.all(const Color(0xFFEAF2FA)),
        columns: const [
          DataColumn(label: Text('Mã thuốc')),
          DataColumn(label: Text('Tên thuốc')),
          DataColumn(label: Text('Nồng độ/hàm lượng')),
          DataColumn(label: Text('Số lượng')),
          DataColumn(label: Text('ĐVT')),
          DataColumn(label: Text('Số ngày')),
          DataColumn(label: Text('Đường dùng')),
          DataColumn(label: Text('Hướng dẫn')),
        ],
        rows: rows.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item['code']?.toString() ?? '')),
              DataCell(
                SizedBox(
                  width: 230,
                  child: Text(item['medicineName']?.toString() ?? ''),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 260,
                  child: Text(item['dosage']?.toString() ?? ''),
                ),
              ),
              DataCell(Text(item['quantity']?.toString() ?? '')),
              DataCell(Text(item['unit']?.toString() ?? 'Viên')),
              DataCell(Text(item['days']?.toString() ?? '')),
              DataCell(Text(item['route']?.toString() ?? 'Uống')),
              DataCell(
                SizedBox(
                  width: 260,
                  child: Text(
                    item['instruction']?.toString() ??
                        item['dosage']?.toString() ??
                        '',
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget serviceUsageVisitPanel(AdminRecord record) {
    final usages = relatedRecords(AdminRoute.serviceUsages, record);
    return panel(
      title: 'Phiếu chỉ định dịch vụ',
      actions: [
        ElevatedButton.icon(
          onPressed: record.data['status'] == 'IN_EXAM'
              ? () => showServiceOrderSheet(record)
              : null,
          icon: const Icon(Icons.medical_services_outlined),
          label: const Text('Tạo phiếu chỉ định dịch vụ'),
        ),
        OutlinedButton.icon(
          onPressed: () => showOrderPrintPreview(
            record,
            relatedRecords(AdminRoute.labResults, record),
            relatedRecords(AdminRoute.imagingResults, record),
            usages,
          ),
          icon: const Icon(Icons.print_outlined),
          label: const Text('In phiếu'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hisPatientStrip(record),
          const SizedBox(height: 8),
          hisDataBlock(
            title: 'Danh sách dịch vụ đã chỉ định',
            child: usages.isEmpty
                ? emptyHisBox('Chưa có dịch vụ/vật tư được chỉ định.')
                : horizontalTable(
                    DataTable(
                      dataRowMinHeight: 30,
                      dataRowMaxHeight: 38,
                      headingRowHeight: 30,
                      columnSpacing: 18,
                      horizontalMargin: 8,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFEAF2FA),
                      ),
                      columns: const [
                        DataColumn(label: Text('Mã dịch vụ')),
                        DataColumn(label: Text('Tên dịch vụ')),
                        DataColumn(label: Text('Số lượng')),
                        DataColumn(label: Text('Đơn vị tính')),
                        DataColumn(label: Text('Đơn giá')),
                        DataColumn(label: Text('Thành tiền')),
                        DataColumn(label: Text('Trạng thái')),
                        DataColumn(label: Text('Ghi chú')),
                      ],
                      rows: usages.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                shortCode(
                                  item,
                                  servicePrefix(item.data['itemType']),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 280,
                                child: Text(
                                  item.data['itemName']?.toString() ?? '',
                                ),
                              ),
                            ),
                            DataCell(
                              Text(item.data['quantity']?.toString() ?? '1'),
                            ),
                            DataCell(
                              Text(item.data['unit']?.toString() ?? 'Lần'),
                            ),
                            DataCell(
                              Text(item.data['unitPrice']?.toString() ?? ''),
                            ),
                            DataCell(
                              Text(item.data['amount']?.toString() ?? ''),
                            ),
                            DataCell(
                              statusPill(item.data['status']?.toString() ?? ''),
                            ),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  item.data['note']?.toString() ?? '',
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
          if (record.data['status'] != 'IN_EXAM') ...[
            const SizedBox(height: 8),
            const Text(
              'Cần bấm "Bắt đầu khám" trước khi tạo phiếu chỉ định mới.',
              style: TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  AdminRecord? selectedRelatedRecord(List<AdminRecord> items, String? id) {
    if (items.isEmpty) return null;
    if (id != null) {
      final matches = items.where((item) => item.id == id);
      if (matches.isNotEmpty) return matches.first;
    }
    return items.first;
  }

  List<String> uniqueLabels(Iterable<String> labels) {
    final result = <String>[];
    for (final label in labels) {
      final trimmed = label.trim();
      if (trimmed.isEmpty || result.contains(trimmed)) continue;
      result.add(trimmed);
    }
    return result;
  }

  String servicePlace(AdminRecord item, AdminRecord appointment) {
    final candidates = [
      item.data['place'],
      item.data['roomName'],
      item.data['department'],
      item.data['departmentName'],
      appointment.data['department'],
    ];
    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return 'Khoa Khám Bệnh';
  }

  String shortCode(AdminRecord item, String prefix) {
    final order = item.data['orderId']?.toString() ?? '';
    if (order.isNotEmpty)
      return order.length > 8
          ? '$prefix-${order.substring(0, 8)}'
          : '$prefix-$order';
    final id = item.id.replaceAll('-', '');
    return '$prefix-${id.length > 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()}';
  }

  String servicePrefix(dynamic itemType) {
    switch (itemType?.toString()) {
      case 'LAB':
        return 'XN';
      case 'IMAGING':
        return 'CDHA';
      case 'SUPPLY':
        return 'VT';
      case 'BED':
        return 'GB';
      case 'PACKAGE':
        return 'GOI';
      default:
        return 'DV';
    }
  }

  WidgetStateProperty<Color?> hisSelectedRowColor(bool selected) {
    return WidgetStateProperty.resolveWith((states) {
      if (selected) return const Color(0xFFFFF59D);
      return null;
    });
  }

  Widget horizontalTable(Widget child) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: child,
      ),
    );
  }

  Widget hisDataBlock({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFBCD3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hisGridTitle(title),
          Padding(padding: const EdgeInsets.all(8), child: child),
        ],
      ),
    );
  }

  Widget emptyHisBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      color: const Color(0xFFF8FAFC),
      child: Text(text, style: const TextStyle(color: Color(0xFF64748B))),
    );
  }

  Widget hisPlaceSelector({
    required List<String> places,
    required String activePlace,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: places.map((place) {
        final active = place == activePlace;
        return InkWell(
          onTap: () => onSelect(place),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF0059A6) : const Color(0xFFF1F5F9),
              border: Border.all(color: const Color(0xFFBCD3EA)),
            ),
            child: Text(
              place,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<ServiceOrderCategory> serviceOrderCategories() {
    return const [
      ServiceOrderCategory(
        label: 'Xét nghiệm (F6)',
        catalogRoute: AdminRoute.labServices,
        targetRoute: AdminRoute.labResults,
        itemType: 'LAB',
        icon: Icons.biotech_outlined,
      ),
      ServiceOrderCategory(
        label: 'CĐHA và TDCN (F7)',
        catalogRoute: AdminRoute.imagingServices,
        targetRoute: AdminRoute.imagingResults,
        itemType: 'IMAGING',
        icon: Icons.image_search_outlined,
      ),
      ServiceOrderCategory(
        label: 'Gói dịch vụ',
        catalogRoute: AdminRoute.technicalServices,
        targetRoute: AdminRoute.serviceUsages,
        itemType: 'PACKAGE',
        icon: Icons.inventory_2_outlined,
      ),
    ];
  }

  Future<void> showServiceOrderSheet(AdminRecord appointment) async {
    final categories = serviceOrderCategories();
    for (final category in categories) {
      await widget.service.lookup(category.catalogRoute);
    }
    if (!mounted) return;

    var activeCategory = categories.first;
    final selectedItems = <Map<String, dynamic>>[];
    final searchController = TextEditingController();

    final result = await showDialog<ServiceOrderDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final query = searchController.text.trim().toLowerCase();
            final catalogs = activeCatalogs(activeCategory.catalogRoute).where((
              catalog,
            ) {
              if (query.isEmpty) return true;
              return catalog.data.values.any(
                (value) => value.toString().toLowerCase().contains(query),
              );
            }).toList();
            final selectedIds = selectedItems
                .map((item) => (item['catalog'] as AdminRecord).id)
                .toSet();
            final totalAmount = selectedItems.fold<int>(
              0,
              (sum, item) => sum + serviceOrderLineAmount(item),
            );
            final insurancePaid = selectedItems.fold<int>(
              0,
              (sum, item) => sum + serviceOrderInsurancePaid(item),
            );
            final patientPaid = totalAmount - insurancePaid;

            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 1180,
                height: 720,
                child: Column(
                  children: [
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      color: const Color(0xFF0059A6),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tạo phiếu chỉ định dịch vụ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Đóng',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 470,
                            child: Column(
                              children: [
                                Container(
                                  height: 34,
                                  color: const Color(0xFFF1F5F9),
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: categories.map((category) {
                                      final active =
                                          category.label ==
                                          activeCategory.label;
                                      return InkWell(
                                        onTap: () => setDialogState(
                                          () => activeCategory = category,
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          color: active
                                              ? const Color(0xFF0059A6)
                                              : const Color(0xFFF1F5F9),
                                          child: Row(
                                            children: [
                                              Icon(
                                                category.icon,
                                                size: 15,
                                                color: active
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                category.label,
                                                style: TextStyle(
                                                  color: active
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: TextField(
                                    controller: searchController,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: const InputDecoration(
                                      hintText: 'Tìm mã hoặc tên dịch vụ',
                                      isDense: true,
                                      prefixIcon: Icon(Icons.search, size: 16),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                                Expanded(
                                  child: catalogs.isEmpty
                                      ? emptyHisBox('Chưa có danh mục phù hợp.')
                                      : Scrollbar(
                                          thumbVisibility: true,
                                          child: ListView.separated(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            itemCount: catalogs.length,
                                            separatorBuilder: (_, __) =>
                                                const Divider(height: 1),
                                            itemBuilder: (context, index) {
                                              final catalog = catalogs[index];
                                              final checked = selectedIds
                                                  .contains(catalog.id);
                                              return InkWell(
                                                onTap: () {
                                                  setDialogState(() {
                                                    if (checked) {
                                                      selectedItems.removeWhere(
                                                        (item) =>
                                                            (item['catalog']
                                                                    as AdminRecord)
                                                                .id ==
                                                            catalog.id,
                                                      );
                                                    } else {
                                                      selectedItems.add({
                                                        'category':
                                                            activeCategory,
                                                        'catalog': catalog,
                                                        'quantity': '1',
                                                        'insurancePercent': '0',
                                                        'note':
                                                            catalog
                                                                .data['description']
                                                                ?.toString() ??
                                                            '',
                                                      });
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  color: checked
                                                      ? const Color(0xFFFFF59D)
                                                      : null,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Checkbox(
                                                        value: checked,
                                                        onChanged: (_) {
                                                          setDialogState(() {
                                                            if (checked) {
                                                              selectedItems.removeWhere(
                                                                (item) =>
                                                                    (item['catalog']
                                                                            as AdminRecord)
                                                                        .id ==
                                                                    catalog.id,
                                                              );
                                                            } else {
                                                              selectedItems.add({
                                                                'category':
                                                                    activeCategory,
                                                                'catalog':
                                                                    catalog,
                                                                'quantity': '1',
                                                                'insurancePercent':
                                                                    '0',
                                                                'note':
                                                                    catalog
                                                                        .data['description']
                                                                        ?.toString() ??
                                                                    '',
                                                              });
                                                            }
                                                          });
                                                        },
                                                      ),
                                                      SizedBox(
                                                        width: 96,
                                                        child: Text(
                                                          catalog.data['code']
                                                                  ?.toString() ??
                                                              '',
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          catalog.data['name']
                                                                  ?.toString() ??
                                                              '',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 86,
                                                        child: Text(
                                                          formatMoney(
                                                            catalog
                                                                .data['price'],
                                                          ),
                                                          textAlign:
                                                              TextAlign.right,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: Color(
                                                                  0xFF0059A6,
                                                                ),
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      medicalReadonlyField(
                                        'Mã BN',
                                        appointment.data['patientCode'],
                                        width: 170,
                                      ),
                                      medicalReadonlyField(
                                        'Họ tên',
                                        appointment.data['patient'],
                                        width: 250,
                                      ),
                                      medicalReadonlyField(
                                        'Năm sinh',
                                        birthYear(
                                          appointment.data['patientDob'],
                                        ),
                                        width: 110,
                                      ),
                                      medicalReadonlyField(
                                        'Địa chỉ',
                                        appointment.data['patientAddress'] ??
                                            appointment.data['address'],
                                        width: 360,
                                      ),
                                      medicalReadonlyField(
                                        'Đối tượng',
                                        appointment.data['insuranceNo']
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true
                                            ? 'BHYT'
                                            : 'Thu phí',
                                        width: 170,
                                      ),
                                      medicalReadonlyField(
                                        'Số thẻ',
                                        appointment.data['insuranceNo'],
                                        width: 250,
                                      ),
                                      medicalReadonlyField(
                                        'TG chỉ định',
                                        DateTime.now().toIso8601String(),
                                        width: 230,
                                      ),
                                      medicalReadonlyField(
                                        'Chẩn đoán',
                                        appointment.data['diagnosis'] ??
                                            appointment.data['note'],
                                        width: 360,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: hisDataBlock(
                                    title: 'Danh sách dịch vụ chỉ định',
                                    child: selectedItems.isEmpty
                                        ? emptyHisBox(
                                            'Chọn dịch vụ bên trái để thêm vào phiếu.',
                                          )
                                        : horizontalTable(
                                            DataTable(
                                              dataRowMinHeight: 34,
                                              dataRowMaxHeight: 58,
                                              headingRowHeight: 30,
                                              columnSpacing: 16,
                                              horizontalMargin: 8,
                                              headingRowColor:
                                                  WidgetStateProperty.all(
                                                    const Color(0xFFEAF2FA),
                                                  ),
                                              columns: const [
                                                DataColumn(label: Text('')),
                                                DataColumn(
                                                  label: Text('Tên dịch vụ'),
                                                ),
                                                DataColumn(label: Text('SL')),
                                                DataColumn(
                                                  label: Text('Loại MBP'),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    'Phòng thực hiện',
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text('Thành tiền'),
                                                ),
                                                DataColumn(
                                                  label: Text('Ghi chú'),
                                                ),
                                              ],
                                              rows: selectedItems.asMap().entries.map((
                                                entry,
                                              ) {
                                                final item = entry.value;
                                                final category =
                                                    item['category']
                                                        as ServiceOrderCategory;
                                                final catalog =
                                                    item['catalog']
                                                        as AdminRecord;
                                                return DataRow(
                                                  color:
                                                      WidgetStateProperty.all(
                                                        entry.key.isEven
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFFF6FAFE,
                                                              ),
                                                      ),
                                                  cells: [
                                                    DataCell(
                                                      IconButton(
                                                        tooltip: 'Bỏ dòng',
                                                        visualDensity:
                                                            VisualDensity
                                                                .compact,
                                                        onPressed: () =>
                                                            setDialogState(
                                                              () => selectedItems
                                                                  .removeAt(
                                                                    entry.key,
                                                                  ),
                                                            ),
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                          size: 16,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 260,
                                                        child: Text(
                                                          catalog.data['name']
                                                                  ?.toString() ??
                                                              '',
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        item['quantity']
                                                                ?.toString() ??
                                                            '1',
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        serviceOrderTypeText(
                                                          category.itemType,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 210,
                                                        child: Text(
                                                          defaultExecutionRoom(
                                                            category,
                                                            appointment,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        formatMoney(
                                                          serviceOrderLineAmount(
                                                            item,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 180,
                                                        child: Text(
                                                          item['note']
                                                                  ?.toString() ??
                                                              '',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                    border: Border(
                                      top: BorderSide(color: Color(0xFFBCD3EA)),
                                    ),
                                  ),
                                  child: Wrap(
                                    spacing: 28,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        'Tổng chi phí: ${formatMoney(totalAmount)}',
                                        style: const TextStyle(
                                          color: Color(0xFF0059A6),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        'BH trả: ${formatMoney(insurancePaid)}',
                                      ),
                                      Text(
                                        'Bệnh nhân trả: ${formatMoney(patientPaid)}',
                                        style: const TextStyle(
                                          color: Color(0xFF0059A6),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      color: const Color(0xFFF1F5F9),
                      child: Row(
                        children: [
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                            label: const Text('Đóng'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: selectedItems.isEmpty
                                ? null
                                : () => Navigator.pop(
                                    dialogContext,
                                    ServiceOrderDialogResult(
                                      selectedItems
                                          .map(
                                            (item) =>
                                                Map<String, dynamic>.from(item),
                                          )
                                          .toList(),
                                    ),
                                  ),
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Lưu'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: selectedItems.isEmpty
                                ? null
                                : () => Navigator.pop(
                                    dialogContext,
                                    ServiceOrderDialogResult(
                                      selectedItems
                                          .map(
                                            (item) =>
                                                Map<String, dynamic>.from(item),
                                          )
                                          .toList(),
                                    ),
                                  ),
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('Lưu & In'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
    if (result == null || result.items.isEmpty) return;
    await saveServiceOrderSheet(appointment, result.items);
  }

  int serviceOrderLineAmount(Map<String, dynamic> item) {
    final catalog = item['catalog'] as AdminRecord;
    final quantity = quantityAsDouble(item['quantity']?.toString() ?? '1');
    return (moneyAsInt(catalog.data['price']) * quantity).round();
  }

  int serviceOrderInsurancePaid(Map<String, dynamic> item) {
    final amount = serviceOrderLineAmount(item);
    final percent =
        (double.tryParse(item['insurancePercent']?.toString() ?? '0') ?? 0)
            .clamp(0, 100);
    return (amount * percent / 100).round();
  }

  String serviceOrderTypeText(String itemType) {
    switch (itemType) {
      case 'LAB':
        return 'Xét nghiệm';
      case 'IMAGING':
        return 'CĐHA';
      case 'SURGERY':
        return 'PTTT';
      case 'PACKAGE':
        return 'Gói';
      default:
        return 'Dịch vụ';
    }
  }

  String defaultExecutionRoom(
    ServiceOrderCategory category,
    AdminRecord appointment,
  ) {
    switch (category.itemType) {
      case 'LAB':
        return 'Khoa Xét nghiệm';
      case 'IMAGING':
        return 'Khoa Chẩn đoán hình ảnh';
      case 'SURGERY':
        return 'Phòng thủ thuật';
      default:
        return appointment.data['department']?.toString() ?? 'Phòng khám';
    }
  }

  Future<void> saveServiceOrderSheet(
    AdminRecord visit,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final item in items) {
        final category = item['category'] as ServiceOrderCategory;
        grouped.putIfAbsent(category.itemType, () => []).add(item);
      }

      for (final entry in grouped.entries) {
        final orderItems = entry.value.map((item) {
          final catalog = item['catalog'] as AdminRecord;
          final amount = serviceOrderLineAmount(item);
          final insurancePayAmount = serviceOrderInsurancePaid(item);
          return {
            'itemType': entry.key,
            'itemId': catalog.id,
            'itemName': catalog.data['name'],
            'quantity': item['quantity']?.toString() ?? '1',
            'unitPrice': moneyAsInt(catalog.data['price']),
            'amount': amount,
            'insuranceCovered': insurancePayAmount > 0,
            'insurancePayAmount': insurancePayAmount,
            'patientPayAmount': amount - insurancePayAmount,
          };
        }).toList();

        await widget.service.createServiceOrder(visit.id, {
          'encounterId': visit.data['encounterId'],
          'doctorId': visit.data['doctorId'],
          'departmentId': visit.data['departmentId'],
          'orderType': entry.key,
          'status': 'DRAFT',
          'items': orderItems,
        });
      }
      await widget.service.loadRecords(AdminRoute.serviceOrders);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã lưu ${grouped.length} phiếu với ${items.length} dịch vụ chỉ định',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget visitRelatedPanel({
    required AdminRecord record,
    required String title,
    required AdminRoute route,
    required IconData icon,
    required String emptyText,
    required String? actionLabel,
    required Future<void> Function()? onCreate,
    required String Function(AdminRecord item) subtitle,
  }) {
    final items = relatedRecords(route, record);
    final inProgress = record.data['status'] == 'IN_EXAM';
    return panel(
      title: title,
      actions: [
        if (actionLabel != null)
          ElevatedButton.icon(
            onPressed: inProgress ? onCreate : null,
            icon: Icon(icon),
            label: Text(actionLabel),
          ),
        OutlinedButton.icon(
          onPressed: () => showOrderPrintPreview(
            record,
            relatedRecords(AdminRoute.labResults, record),
            relatedRecords(AdminRoute.imagingResults, record),
            relatedRecords(AdminRoute.serviceUsages, record),
          ),
          icon: const Icon(Icons.print_outlined),
          label: const Text('In phiếu'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hisPatientStrip(record),
          const SizedBox(height: 10),
          clinicalList(title, items, icon, subtitle),
          if (!inProgress && actionLabel != null) ...[
            const SizedBox(height: 10),
            const Text(
              'Cần bắt đầu khám trước khi tạo chỉ định mới.',
              style: TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (items.isEmpty) ...[
            const SizedBox(height: 10),
            Text(emptyText, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ],
      ),
    );
  }

  Widget workflowDetail(AdminRecord record) {
    if (isVisitRoute || widget.module.route == AdminRoute.reception) {
      return appointmentDetail(record, embedded: true);
    }
    if (widget.module.route == AdminRoute.labResults) {
      return labResultDetail(record, embedded: true);
    }
    if (widget.module.route == AdminRoute.imagingResults) {
      return imagingResultDetail(record, embedded: true);
    }
    if (widget.module.route == AdminRoute.prescriptions) {
      return prescriptionDetail(record, embedded: true);
    }
    if (widget.module.route == AdminRoute.payments) {
      return billingDetail(record, embedded: true);
    }
    if (widget.module.route == AdminRoute.inpatient) {
      return inpatientDetail(record);
    }

    final fields = widget.module.fields
        .where((field) => record.data.containsKey(field.key))
        .toList();
    return panel(
      title: primaryTitle(record),
      actions: [
        ...workflowQuickActions(record),
        IconButton(
          tooltip: 'Sửa nhanh',
          onPressed: () => setState(() {
            selected = record;
            mode = ModuleMode.form;
          }),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: fields
                .map(
                  (field) => detailSection(
                    title: field.label,
                    children: [detailValue(field, record)],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget inpatientDetail(AdminRecord record) {
    final data = record.data;
    return panel(
      title: 'Bệnh án nội trú ${data['admissionCode'] ?? ''}',
      actions: [
        ...workflowQuickActions(record),
        IconButton(
          tooltip: 'Sửa hồ sơ nội trú',
          onPressed: () => setState(() {
            selected = record;
            mode = ModuleMode.form;
          }),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          hisPatientStrip(record),
          const SizedBox(height: 10),
          hisDataBlock(
            title: 'Thông tin điều trị nội trú',
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  medicalReadonlyField(
                    'Mã vào viện',
                    data['admissionCode'],
                    width: 180,
                  ),
                  medicalReadonlyField(
                    'Khoa điều trị',
                    data['department'],
                    width: 240,
                  ),
                  medicalReadonlyField(
                    'Bác sĩ điều trị',
                    data['doctor'],
                    width: 240,
                  ),
                  medicalReadonlyField(
                    'Buồng / phòng',
                    data['roomName'],
                    width: 190,
                  ),
                  medicalReadonlyField('Giường', data['bedCode'], width: 130),
                  medicalReadonlyField(
                    'Ngày vào viện',
                    data['admittedAt'],
                    width: 210,
                  ),
                  medicalReadonlyField(
                    'Ngày ra viện',
                    data['dischargedAt'],
                    width: 210,
                  ),
                  medicalReadonlyField(
                    'Trạng thái',
                    workflowStages()[workflowStatus(record)] ??
                        workflowStatus(record),
                    width: 180,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          hisDataBlock(
            title: 'Lý do vào viện và chẩn đoán',
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  medicalReadonlyField(
                    'Lý do vào viện',
                    data['reason'],
                    width: 420,
                  ),
                  medicalReadonlyField(
                    'Chẩn đoán',
                    data['diagnosis'],
                    width: 420,
                  ),
                  medicalReadonlyField(
                    'Ghi chú điều trị',
                    data['note'],
                    width: 520,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> workflowQuickActions(AdminRecord record) {
    switch (widget.module.route) {
      case AdminRoute.inpatient:
        return [
          quickAction(
            'Đang điều trị',
            Icons.medical_services_outlined,
            () => updateStatus(record, 'IN_TREATMENT'),
          ),
          quickAction(
            'Ra viện',
            Icons.logout_outlined,
            () => updateStatus(record, 'DISCHARGED'),
          ),
          quickAction(
            'Hủy',
            Icons.cancel_outlined,
            () => updateStatus(record, 'CANCELLED'),
            danger: true,
          ),
        ];
      case AdminRoute.queueTickets:
        return [
          quickAction(
            'Hoàn tất',
            Icons.check_circle_outline,
            () => updateStatus(record, 'DONE'),
          ),
          quickAction(
            'Hủy',
            Icons.cancel_outlined,
            () => updateStatus(record, 'CANCELLED'),
            danger: true,
          ),
        ];
      case AdminRoute.labResults:
        return [
          quickAction(
            'Lấy mẫu',
            Icons.science_outlined,
            () => updateStatus(record, 'Đã lấy mẫu', key: 'statusLabel'),
          ),
          quickAction(
            'Chạy máy',
            Icons.precision_manufacturing_outlined,
            () => updateStatus(record, 'Đang chạy máy', key: 'statusLabel'),
          ),
          quickAction(
            'Chờ duyệt',
            Icons.fact_check_outlined,
            () => updateStatus(record, 'Chờ duyệt', key: 'statusLabel'),
          ),
          quickAction(
            'Duyệt kết quả',
            Icons.verified_outlined,
            () => updateStatus(record, 'Đã duyệt', key: 'statusLabel'),
          ),
        ];
      case AdminRoute.imagingResults:
        return [
          quickAction(
            'Đã chụp',
            Icons.camera_alt_outlined,
            () => updateStatus(record, 'Đã chụp', key: 'statusLabel'),
          ),
          quickAction(
            'Chờ đọc',
            Icons.rate_review_outlined,
            () => updateStatus(record, 'Chờ đọc', key: 'statusLabel'),
          ),
          quickAction(
            'Chờ duyệt',
            Icons.fact_check_outlined,
            () => updateStatus(record, 'Chờ duyệt', key: 'statusLabel'),
          ),
          quickAction(
            'Duyệt kết quả',
            Icons.verified_outlined,
            () => updateStatus(record, 'Đã duyệt', key: 'statusLabel'),
          ),
        ];
      case AdminRoute.prescriptions:
        return [
          quickAction(
            'Đã phát thuốc',
            Icons.medication_outlined,
            () => updateStatus(record, 'Đã phát thuốc'),
          ),
        ];
      case AdminRoute.payments:
        return [
          quickAction(
            'Đã thanh toán',
            Icons.payments_outlined,
            () => updateStatus(record, 'Đã thanh toán'),
          ),
          quickAction(
            'Hủy phí',
            Icons.cancel_outlined,
            () => updateStatus(record, 'Đã hủy'),
            danger: true,
          ),
        ];
      case AdminRoute.serviceUsages:
        return [
          quickAction(
            'Đã thu',
            Icons.payments_outlined,
            () => updateStatus(record, 'PAID'),
          ),
          quickAction(
            'Hủy',
            Icons.cancel_outlined,
            () => updateStatus(record, 'CANCELLED'),
            danger: true,
          ),
        ];
      case AdminRoute.callbackRequests:
        return [
          quickAction(
            'Đã gọi',
            Icons.phone_callback_outlined,
            () => updateStatus(record, 'CALLED'),
          ),
          quickAction(
            'Hủy',
            Icons.cancel_outlined,
            () => updateStatus(record, 'CANCELLED'),
            danger: true,
          ),
        ];
      default:
        return [];
    }
  }

  Widget quickAction(
    String label,
    IconData icon,
    Future<void> Function() onPressed, {
    bool danger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilledButton.tonalIcon(
        onPressed: () {
          onPressed();
        },
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          foregroundColor: danger
              ? Colors.red.shade700
              : const Color(0xFF007A3D),
        ),
      ),
    );
  }

  Future<void> updateStatus(
    AdminRecord record,
    String nextStatus, {
    String key = 'status',
  }) async {
    final data = Map<String, dynamic>.from(record.data);
    data[key] = nextStatus;
    try {
      await widget.service.update(widget.module.route, record.id, data);
      if (!mounted) return;
      setState(() {
        refreshSelectedRecord(record.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật ${widget.module.singular}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget emptyWorkflowState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 44, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text('Không có hồ sơ cần xử lý'),
        ],
      ),
    );
  }

  Future<void> changeAppointmentState(
    AdminRecord record, {
    required Future<void> Function() action,
    required String message,
  }) async {
    try {
      await action();
      if (!mounted) return;
      setState(() {
        refreshSelectedRecord(record.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> cancelAppointment(AdminRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch hẹn'),
        content: const Text('Bạn có chắc chắn muốn hủy lịch hẹn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.service.cancelAppointment(record.id);
      if (!mounted) return;
      setState(() {
        refreshSelectedRecord(record.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã hủy lịch hẹn')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> showProposeAppointmentDialog(AdminRecord record) async {
    final departments = await widget.service.lookup(AdminRoute.departments);
    final doctors = await widget.service.lookup(AdminRoute.doctors);
    if (!mounted) return;

    String? departmentId;
    String? doctorId;
    DateTime? appointmentDate;
    final noteController = TextEditingController();

    final data = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final departmentName = departmentId == null
                ? ''
                : departments
                      .firstWhere((item) => item.id == departmentId)
                      .data['name']
                      ?.toString();
            final filteredDoctors =
                departmentName == null || departmentName.isEmpty
                ? doctors
                : doctors
                      .where(
                        (doctor) => doctor.data['department'] == departmentName,
                      )
                      .toList();

            return AlertDialog(
              title: const Text('Đề xuất lịch khám'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: departmentId,
                      decoration: const InputDecoration(
                        labelText: 'Khoa khám *',
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
                      onChanged: (value) {
                        setDialogState(() {
                          departmentId = value;
                          doctorId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: doctorId,
                      decoration: const InputDecoration(
                        labelText: 'Bac sĩ *',
                        border: OutlineInputBorder(),
                      ),
                      items: filteredDoctors
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                [
                                      item.data['fullName']?.toString() ?? '',
                                      item.data['title']?.toString() ?? '',
                                    ]
                                    .where((value) => value.isNotEmpty)
                                    .join(' - '),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => doctorId = value),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: now,
                          firstDate: now,
                          lastDate: DateTime(now.year + 2),
                        );
                        if (pickedDate == null) return;
                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime == null) return;
                        setDialogState(() {
                          appointmentDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày giờ đề xuất *',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_month),
                        ),
                        child: Text(
                          appointmentDate == null
                              ? 'Chọn ngày giờ'
                              : appointmentDate!.toIso8601String(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú đề xuất',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed:
                      departmentId == null ||
                          doctorId == null ||
                          appointmentDate == null
                      ? null
                      : () => Navigator.pop(dialogContext, {
                          'departmentId': departmentId!,
                          'doctorId': doctorId!,
                          'appointmentDate': appointmentDate!.toIso8601String(),
                          'proposalNote': noteController.text,
                        }),
                  child: const Text('Gửi đề xuất'),
                ),
              ],
            );
          },
        );
      },
    );

    noteController.dispose();
    if (data == null || !mounted) return;

    try {
      await widget.service.proposeAppointment(
        id: record.id,
        departmentId: data['departmentId']!,
        doctorId: data['doctorId']!,
        appointmentDate: data['appointmentDate']!,
        proposalNote: data['proposalNote'],
      );
      if (!mounted) return;
      setState(() {
        refreshSelectedRecord(record.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi đề xuất lịch khám')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void refreshSelectedRecord(String id) {
    final records = widget.service.records(widget.module.route);
    final matches = records.where((item) => item.id == id);
    if (matches.isNotEmpty) {
      selected = matches.first;
    }
  }

  Widget detail() {
    final record = selected;
    if (record == null) return list();
    if (isVisitRoute || widget.module.route == AdminRoute.reception) {
      return appointmentDetail(record);
    }
    if (widget.module.route == AdminRoute.labResults) {
      return labResultDetail(record);
    }
    if (widget.module.route == AdminRoute.imagingResults) {
      return imagingResultDetail(record);
    }
    if (widget.module.route == AdminRoute.prescriptions) {
      return prescriptionDetail(record);
    }
    if (widget.module.route == AdminRoute.payments) {
      return billingDetail(record);
    }

    return panel(
      title: 'Chi tiết ${widget.module.singular}',
      actions: [
        OutlinedButton.icon(
          onPressed: () => setState(() {
            mode = ModuleMode.list;
          }),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Quay lại'),
        ),
        ElevatedButton.icon(
          onPressed: () => setState(() {
            mode = ModuleMode.form;
          }),
          icon: const Icon(Icons.edit),
          label: const Text('Sửa'),
        ),
      ],
      child: Column(
        children: widget.module.fields.map((field) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    field.label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: detailValue(field, record)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> detailWorkflowActions(
    AdminRecord record, {
    required bool embedded,
  }) {
    return [
      ...workflowQuickActions(record),
      if (!embedded)
        OutlinedButton.icon(
          onPressed: () => setState(() {
            mode = ModuleMode.list;
          }),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Quay lại'),
        ),
      ElevatedButton.icon(
        onPressed: () => setState(() {
          selected = record;
          mode = ModuleMode.form;
        }),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Sửa hồ sơ'),
      ),
    ];
  }

  Widget labResultDetail(AdminRecord record, {bool embedded = false}) {
    final data = record.data;
    final indicators = mapList(data['indicators']);
    final status = data['statusLabel']?.toString() ?? '';
    final abnormalCount = indicators.where(labIndicatorAbnormal).length;

    return panel(
      title: 'Phiếu xét nghiệm',
      actions: detailWorkflowActions(record, embedded: embedded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          clinicalDetailHeader(
            icon: Icons.science_outlined,
            title: data['testType']?.toString() ?? 'Xét nghiệm',
            subtitle: data['patient']?.toString() ?? 'Chưa có bệnh nhân',
            status: status,
            facts: [
              detailFact('Ngày thực hiện', data['performedAt']),
              detailFact('Mã chỉ định', data['orderId']),
              detailFact(
                'Bất thường',
                abnormalCount == 0 ? 'Không' : '$abnormalCount chỉ số',
              ),
            ],
          ),
          const SizedBox(height: 18),
          workflowTimeline(const [
            'Chờ lấy mẫu',
            'Đã lấy mẫu',
            'Đang chạy máy',
            'Chờ duyệt',
            'Đã duyệt',
          ], status),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              detailSection(
                title: 'Kết luận xét nghiệm',
                children: [
                  detailLine('Kết luận', data['conclusion']),
                  detailLine('Bác sĩ nhận định', data['doctorNote']),
                  detailLine('File kết quả', data['pdfUrl']),
                ],
              ),
              detailSection(
                title: 'Thông tin liên kết',
                children: [
                  detailLine('Bệnh nhân', data['patient']),
                  detailLine('Mã lượt khám', data['encounterId']),
                  detailLine('Mã lịch hẹn', data['appointmentId']),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          labIndicatorPanel(indicators),
        ],
      ),
    );
  }

  Widget imagingResultDetail(AdminRecord record, {bool embedded = false}) {
    final data = record.data;
    final status = data['statusLabel']?.toString() ?? '';

    return panel(
      title: 'Phiếu chẩn đoán hình ảnh',
      actions: detailWorkflowActions(record, embedded: embedded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          clinicalDetailHeader(
            icon: Icons.image_search_outlined,
            title: data['title']?.toString() ?? 'Chẩn đoán hình ảnh',
            subtitle: data['patient']?.toString() ?? 'Chưa có bệnh nhân',
            status: status,
            facts: [
              detailFact('Ngày thực hiện', data['performedAt']),
              detailFact('Kỹ thuật', data['technique']),
              detailFact('Bác sĩ đọc', data['doctorName']),
            ],
          ),
          const SizedBox(height: 18),
          workflowTimeline(const [
            'Chờ thực hiện',
            'Đã chụp',
            'Chờ đọc',
            'Chờ duyệt',
            'Đã duyệt',
          ], status),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 820;
              final image = imagingPreview(data['imageUrl']?.toString() ?? '');
              final detail = Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  detailSection(
                    title: 'Kết luận chuyên môn',
                    children: [
                      detailLine('Kết luận', data['conclusion']),
                      detailLine('Bác sĩ chẩn đoán', data['doctorName']),
                      detailLine('Đường dẫn ảnh', data['imageUrl']),
                    ],
                  ),
                  detailSection(
                    title: 'Thông tin chỉ định',
                    children: [
                      detailLine('Bệnh nhân', data['patient']),
                      detailLine('Mã lượt khám', data['encounterId']),
                      detailLine('Mã chỉ định', data['orderId']),
                    ],
                  ),
                ],
              );
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [image, const SizedBox(height: 16), detail],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 360, child: image),
                  const SizedBox(width: 18),
                  Expanded(child: detail),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget prescriptionDetail(AdminRecord record, {bool embedded = false}) {
    final data = record.data;
    final items = mapList(data['items']);
    final lines = items.isEmpty
        ? (data['medicines']?.toString() ?? '')
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .map((line) => {'medicineName': line.trim()})
              .toList()
        : items;

    return panel(
      title: 'Đơn thuốc',
      actions: detailWorkflowActions(record, embedded: embedded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          clinicalDetailHeader(
            icon: Icons.medication_outlined,
            title: 'Đơn thuốc ${data['prescribedAt'] ?? ''}',
            subtitle: data['patient']?.toString() ?? 'Chưa có bệnh nhân',
            status: data['status']?.toString() ?? '',
            facts: [
              detailFact('Bác sĩ kê', data['doctor']),
              detailFact('Ngày kê', data['prescribedAt']),
              detailFact('Số dòng thuốc', lines.length),
            ],
          ),
          const SizedBox(height: 18),
          medicationPanel(lines),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              detailSection(
                title: 'Thông tin liên kết',
                children: [
                  detailLine('Mã lượt khám', data['encounterId']),
                  detailLine('Mã lịch hẹn', data['appointmentId']),
                  detailLine('Mã chỉ định', data['orderId']),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget billingDetail(AdminRecord record, {bool embedded = false}) {
    final data = record.data;
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    return panel(
      title: 'Chi tiết viện phí',
      actions: [
        ...workflowQuickActions(record),
        if (!embedded)
          OutlinedButton.icon(
            onPressed: () => setState(() {
              mode = ModuleMode.list;
            }),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại'),
          ),
        ElevatedButton.icon(
          onPressed: () => openBillingCostStatement(
            data: data,
            organizationName: widget.service.organizationName,
          ),
          icon: const Icon(Icons.print_outlined),
          label: const Text('In bảng kê'),
        ),
        ElevatedButton.icon(
          onPressed: () => setState(() {
            selected = record;
            mode = ModuleMode.form;
          }),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Sửa'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              detailSection(
                title: 'Thông tin bệnh nhân',
                children: [
                  detailLine('Họ tên', data['patient']),
                  detailLine('Mã bệnh nhân', data['patientCode']),
                  detailLine('Số điện thoại', data['patientPhone']),
                  detailLine('Ngày sinh', data['patientDob']),
                  detailLine('Giới tính', genderText(data['patientGender'])),
                ],
              ),
              detailSection(
                title: 'Thẻ bảo hiểm',
                children: [
                  detailLine('Mã BHYT', data['insuranceNo']),
                  detailLine('Trạng thái', data['status']),
                  detailLine('Ngày phát sinh', data['createdAt']),
                  detailLine('Ghi chú', data['note']),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Chi tiết phát sinh',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text('Chưa có dòng viện phí.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF1F8F3),
                ),
                columns: const [
                  DataColumn(label: Text('Loại')),
                  DataColumn(label: Text('Tên dịch vụ / thuốc / vật tư')),
                  DataColumn(numeric: true, label: Text('SL')),
                  DataColumn(numeric: true, label: Text('Đơn giá')),
                  DataColumn(numeric: true, label: Text('Thành tiền')),
                  DataColumn(numeric: true, label: Text('BHYT %')),
                  DataColumn(numeric: true, label: Text('BHYT trả')),
                  DataColumn(numeric: true, label: Text('Người bệnh trả')),
                ],
                rows: items
                    .map(
                      (item) => DataRow(
                        cells: [
                          DataCell(Text(billingItemTypeText(item['itemType']))),
                          DataCell(
                            SizedBox(
                              width: 260,
                              child: Text(item['itemName']?.toString() ?? ''),
                            ),
                          ),
                          DataCell(Text(item['quantity']?.toString() ?? '1')),
                          DataCell(
                            Text(
                              item['unitPriceText']?.toString() ??
                                  formatMoney(item['unitPrice']),
                            ),
                          ),
                          DataCell(
                            Text(
                              item['amountText']?.toString() ??
                                  formatMoney(item['amount']),
                            ),
                          ),
                          DataCell(Text('${item['insurancePercent'] ?? 0}%')),
                          DataCell(
                            Text(
                              item['insurancePaidText']?.toString() ??
                                  formatMoney(item['insurancePaid']),
                            ),
                          ),
                          DataCell(
                            Text(
                              item['patientPaidText']?.toString() ??
                                  formatMoney(item['patientPaid']),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              billingSummaryTile('Tạm ứng', formatMoney(data['advancePaid'])),
              billingSummaryTile(
                'Tổng giá trị',
                formatMoney(data['totalAmount'] ?? data['amount']),
              ),
              billingSummaryTile(
                'BHYT thanh toán',
                data['insurancePaidText']?.toString() ??
                    formatMoney(data['insurancePaid']),
              ),
              billingSummaryTile(
                'Người bệnh thanh toán',
                data['patientPaidText']?.toString() ??
                    formatMoney(data['patientPaid']),
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget billingSummaryTile(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF007A3D) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? const Color(0xFF007A3D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.white70 : const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: highlight ? Colors.white : const Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String billingItemTypeText(dynamic value) {
    switch (value?.toString()) {
      case 'EXAM_FEE':
        return 'Phí khám';
      case 'LAB':
        return 'Xét nghiệm';
      case 'IMAGING':
        return 'CĐHA';
      case 'SERVICE':
      case 'TECHNICAL_SERVICE':
        return 'DVKT';
      case 'SUPPLY':
        return 'Vật tư';
      case 'BED':
      case 'BED_FEE':
        return 'Giường bệnh';
      case 'MEDICINE':
        return 'Thuốc';
      case 'BILLING':
        return 'Khác';
      default:
        return value?.toString() ?? '';
    }
  }

  Widget appointmentDetail(AdminRecord record, {bool embedded = false}) {
    final data = record.data;
    return panel(
      title: 'Chi tiết lịch hẹn',
      actions: [
        ...appointmentActionButtons(record),
        if (!embedded)
          OutlinedButton.icon(
            onPressed: () => setState(() {
              mode = ModuleMode.list;
            }),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              detailSection(
                title: 'Bệnh nhân',
                children: [
                  detailLine('Họ tên', data['patient']),
                  detailLine('Mã bệnh nhân', data['patientCode']),
                  detailLine('Số điện thoại', data['patientPhone']),
                  detailLine('Ngày sinh', data['patientDob']),
                  detailLine('Giới tính', genderText(data['patientGender'])),
                ],
              ),
              detailSection(
                title: 'Yêu cầu đặt lịch',
                children: [
                  detailLine('Ngày mong muốn', data['requestedAt']),
                  detailLine('Lý do / triệu chứng', data['note']),
                  detailLine('Ngày tạo yêu cầu', data['createdAt']),
                  detailLine('Trạng thái', statusText(data['status'])),
                ],
              ),
              detailSection(
                title: 'Lịch bệnh viện đề xuất',
                children: [
                  detailLine('Khoa', data['department']),
                  detailLine('Bác sĩ', data['doctor']),
                  detailLine('Ngày đề xuất', data['appointmentAt']),
                ],
              ),
              detailSection(
                title: 'Kết quả khám',
                children: [
                  detailLine('Thời điểm hoàn tất', data['completedAt']),
                  detailLine('Chẩn đoán', data['diagnosis']),
                  detailLine('Kết luận', data['conclusion']),
                  detailLine('Ghi chú / hướng điều trị', data['treatmentNote']),
                ],
              ),
            ],
          ),
          if ([
            'CHECKED_IN',
            'IN_PROGRESS',
            'COMPLETED',
          ].contains(data['status']?.toString())) ...[
            const SizedBox(height: 24),
            clinicalWorkspace(record),
          ],
        ],
      ),
    );
  }

  Widget clinicalWorkspace(AdminRecord record) {
    final data = record.data;
    final inProgress = data['status'] == 'IN_PROGRESS';
    final labs = relatedRecords(AdminRoute.labResults, record);
    final imaging = relatedRecords(AdminRoute.imagingResults, record);
    final prescriptions = relatedRecords(AdminRoute.prescriptions, record);
    final usages = relatedRecords(AdminRoute.serviceUsages, record);
    final payments = relatedRecords(AdminRoute.payments, record);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Không gian khám bệnh',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bác sĩ xử lý chỉ định, kết quả, đơn thuốc và viện phí ngay trên phiên khám.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (!inProgress)
                statusPill('Cần bắt đầu khám để chỉ định')
              else
                statusPill('Đang khám'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              clinicalAction(
                'Chỉ định xét nghiệm',
                Icons.science_outlined,
                inProgress ? () => createLabOrder(record) : null,
              ),
              clinicalAction(
                'Chỉ định CĐHA',
                Icons.image_search_outlined,
                inProgress ? () => createImagingOrder(record) : null,
              ),
              clinicalAction(
                'Chỉ định dịch vụ',
                Icons.medical_information_outlined,
                inProgress ? () => createServiceUsage(record) : null,
              ),
              clinicalAction(
                'Vật tư',
                Icons.inventory_2_outlined,
                inProgress ? () => createSupplyUsage(record) : null,
              ),
              clinicalAction(
                'Giường bệnh',
                Icons.bed_outlined,
                inProgress ? () => createBedUsage(record) : null,
              ),
              clinicalAction(
                'Kê đơn thuốc',
                Icons.medication_outlined,
                inProgress ? () => createPrescription(record) : null,
              ),
              clinicalAction(
                'Khoản thu khác',
                Icons.payments_outlined,
                inProgress ? () => createBilling(record) : null,
              ),
              clinicalAction(
                'In phiếu chỉ định',
                Icons.print_outlined,
                () => showOrderPrintPreview(record, labs, imaging, usages),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth > 860;
              final width = twoColumns
                  ? (constraints.maxWidth - 14) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: width,
                    child: clinicalList(
                      'Xét nghiệm',
                      labs,
                      Icons.science_outlined,
                      (item) =>
                          '${item.data['testType'] ?? ''} - ${item.data['statusLabel'] ?? ''}',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: clinicalList(
                      'Chẩn đoán hình ảnh',
                      imaging,
                      Icons.image_search_outlined,
                      (item) =>
                          '${item.data['title'] ?? ''} - ${item.data['statusLabel'] ?? ''}',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: clinicalList(
                      'Đơn thuốc',
                      prescriptions,
                      Icons.medication_outlined,
                      (item) =>
                          '${item.data['status'] ?? ''} - ${item.data['medicines'] ?? ''}',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: clinicalList(
                      'Dịch vụ / viện phí',
                      [...usages, ...payments],
                      Icons.receipt_long_outlined,
                      (item) =>
                          '${item.data['itemName'] ?? item.data['amount'] ?? ''} - ${item.data['status'] ?? ''}',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget clinicalAction(String label, IconData icon, VoidCallback? onPressed) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        foregroundColor: const Color(0xFF007A3D),
        disabledForegroundColor: const Color(0xFF94A3B8),
      ),
    );
  }

  List<AdminRecord> relatedRecords(AdminRoute route, AdminRecord visit) {
    final visitId = visit.id;
    final appointmentId = visit.data['appointmentId']?.toString() ?? '';
    final encounterId = visit.data['encounterId']?.toString() ?? '';
    final patientName = visit.data['patient']?.toString() ?? '';
    final patientCode = visit.data['patientCode']?.toString() ?? '';
    final normalizedPatient = patientName.trim().toLowerCase();
    final normalizedPatientCode = patientCode.trim().toLowerCase();

    return widget.service.records(route).where((record) {
      final recordAppointmentId =
          record.data['appointmentId']?.toString() ?? '';
      final recordVisitId = record.data['visitId']?.toString() ?? '';
      final recordEncounterId = record.data['encounterId']?.toString() ?? '';
      final recordPatientCode =
          record.data['patientCode']?.toString().toLowerCase() ?? '';

      if (recordVisitId.isNotEmpty && recordVisitId == visitId) {
        return true;
      }

      if (recordAppointmentId.isNotEmpty &&
          appointmentId.isNotEmpty &&
          recordAppointmentId == appointmentId) {
        return true;
      }

      if (encounterId.isNotEmpty &&
          recordEncounterId.isNotEmpty &&
          recordEncounterId == encounterId) {
        return true;
      }

      if (normalizedPatientCode.isNotEmpty &&
          recordPatientCode.isNotEmpty &&
          recordPatientCode == normalizedPatientCode) {
        return true;
      }

      if (normalizedPatient.isEmpty) return false;
      final patient = record.data['patient']?.toString().toLowerCase() ?? '';
      return patient == normalizedPatient ||
          patient.contains(normalizedPatient);
    }).toList();
  }

  Widget clinicalList(
    String title,
    List<AdminRecord> items,
    IconData icon,
    String Function(AdminRecord) subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF007A3D), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$title (${items.length})',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'Chưa phát sinh',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...items
                .take(6)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Color(0xFF007A3D),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            subtitle(item),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> createLabOrder(AdminRecord appointment) async {
    final data = await showCatalogOrderDialog(
      title: 'Chỉ định xét nghiệm',
      catalogRoute: AdminRoute.labServices,
      emptyText:
          'Chưa có danh mục xét nghiệm. Vui lòng thêm trong Danh mục xét nghiệm trước.',
      noteLabel: 'Ghi chú chỉ định',
    );
    if (data == null) return;
    await createClinicalRecord(AdminRoute.labResults, {
      'patient': appointment.data['patient'],
      'appointmentId': appointment.id,
      'encounterId': appointment.data['encounterId'],
      'testType': data['primary'],
      'catalogId': data['catalogId'],
      'quantity': data['quantity'],
      'unitPrice': data['unitPrice'],
      'amount': data['amount'],
      'insurancePercent': data['insurancePercent'],
      'insuranceCovered': data['insuranceCovered'],
      'performedAt': DateTime.now().toIso8601String(),
      'conclusion': 'Chờ kết quả',
      'doctorNote': data['note'],
      'statusLabel': 'Chờ lấy mẫu',
    }, 'Đã tạo chỉ định xét nghiệm');
  }

  Future<void> createImagingOrder(AdminRecord appointment) async {
    final data = await showCatalogOrderDialog(
      title: 'Chỉ định chẩn đoán hình ảnh',
      catalogRoute: AdminRoute.imagingServices,
      emptyText:
          'Chưa có danh mục CĐHA. Vui lòng thêm trong Dịch vụ CĐHA trước.',
      noteLabel: 'Lý do / vùng khảo sát',
    );
    if (data == null) return;
    await createClinicalRecord(AdminRoute.imagingResults, {
      'patient': appointment.data['patient'],
      'appointmentId': appointment.id,
      'encounterId': appointment.data['encounterId'],
      'title': data['primary'],
      'catalogId': data['catalogId'],
      'quantity': data['quantity'],
      'unitPrice': data['unitPrice'],
      'amount': data['amount'],
      'insurancePercent': data['insurancePercent'],
      'insuranceCovered': data['insuranceCovered'],
      'technique': data['note'],
      'performedAt': DateTime.now().toIso8601String(),
      'conclusion': 'Chờ kết quả',
      'statusLabel': 'Chờ thực hiện',
    }, 'Đã tạo chỉ định CĐHA');
  }

  Future<void> createServiceUsage(AdminRecord appointment) async {
    final data = await showCatalogOrderDialog(
      title: 'Chỉ định dịch vụ',
      catalogRoute: AdminRoute.technicalServices,
      emptyText:
          'Chưa có danh mục dịch vụ kỹ thuật. Vui lòng thêm trong Dịch vụ kỹ thuật trước.',
      noteLabel: 'Ghi chú chỉ định',
    );
    if (data == null) return;
    await createClinicalRecord(AdminRoute.serviceUsages, {
      'patient': appointment.data['patient'],
      'appointmentId': appointment.id,
      'encounterId': appointment.data['encounterId'],
      'itemType': 'SERVICE',
      'itemName': data['primary'],
      'catalogId': data['catalogId'],
      'quantity': data['quantity'],
      'unitPrice': data['unitPrice'],
      'amount': data['amount'],
      'insurancePercent': data['insurancePercent'],
      'insuranceCovered': data['insuranceCovered'],
      'note': data['note'],
      'usedAt': DateTime.now().toIso8601String(),
      'status': 'UNPAID',
    }, 'Đã tạo chỉ định dịch vụ');
  }

  Future<void> createSupplyUsage(AdminRecord appointment) async {
    final data = await showCatalogOrderDialog(
      title: 'Chỉ định vật tư y tế',
      catalogRoute: AdminRoute.supplies,
      emptyText:
          'Chưa có danh mục vật tư y tế. Vui lòng thêm trong Vật tư y tế trước.',
      noteLabel: 'Ghi chú sử dụng',
    );
    if (data == null) return;
    await createClinicalRecord(AdminRoute.serviceUsages, {
      'patient': appointment.data['patient'],
      'appointmentId': appointment.id,
      'encounterId': appointment.data['encounterId'],
      'itemType': 'SUPPLY',
      'itemName': data['primary'],
      'catalogId': data['catalogId'],
      'quantity': data['quantity'],
      'unitPrice': data['unitPrice'],
      'amount': data['amount'],
      'insurancePercent': data['insurancePercent'],
      'insuranceCovered': data['insuranceCovered'],
      'note': data['note'],
      'usedAt': DateTime.now().toIso8601String(),
      'status': 'UNPAID',
    }, 'Đã thêm vật tư vào phiên khám');
  }

  Future<void> createBedUsage(AdminRecord appointment) async {
    final data = await showCatalogOrderDialog(
      title: 'Chọn giường bệnh',
      catalogRoute: AdminRoute.bedFees,
      emptyText:
          'Chưa có danh mục giá giường. Vui lòng thêm trong Giá giường trước.',
      noteLabel: 'Số giường / ghi chú',
    );
    if (data == null) return;
    await createClinicalRecord(AdminRoute.serviceUsages, {
      'patient': appointment.data['patient'],
      'appointmentId': appointment.id,
      'encounterId': appointment.data['encounterId'],
      'itemType': 'BED',
      'itemName': data['primary'],
      'catalogId': data['catalogId'],
      'quantity': data['quantity'],
      'unitPrice': data['unitPrice'],
      'amount': data['amount'],
      'insurancePercent': data['insurancePercent'],
      'insuranceCovered': data['insuranceCovered'],
      'note': data['note'],
      'usedAt': DateTime.now().toIso8601String(),
      'status': 'UNPAID',
    }, 'Đã thêm tiền giường vào viện phí');
  }

  Future<void> createPrescription(AdminRecord appointment) async {
    final data = await showCatalogOrderDialog(
      title: 'Kê đơn thuốc',
      catalogRoute: AdminRoute.medicines,
      emptyText:
          'Chưa có danh mục thuốc. Vui lòng thêm trong Danh mục thuốc trước.',
      noteLabel: 'Liều dùng',
      noteHint: 'VD: Uống 1 viên x 2 lần/ngày sau ăn',
    );
    if (data == null) return;
    await createClinicalRecord(AdminRoute.prescriptions, {
      'patient': appointment.data['patient'],
      'appointmentId': appointment.id,
      'encounterId': appointment.data['encounterId'],
      'doctor': appointment.data['doctor'],
      'prescribedAt': DateTime.now().toIso8601String(),
      'status': 'Mới',
      'itemName': data['primary'],
      'catalogId': data['catalogId'],
      'quantity': data['quantity'],
      'unitPrice': data['unitPrice'],
      'amount': data['amount'],
      'insurancePercent': data['insurancePercent'],
      'insuranceCovered': data['insuranceCovered'],
      'medicines': jsonEncode([
        {
          'medicineName': data['primary'],
          'dosage': data['note'],
          'quantity': data['quantity'],
          'note': '',
        },
      ]),
    }, 'Đã kê đơn thuốc');
  }

  Future<void> createBilling(AdminRecord appointment) async {
    final data = await showCatalogOrderDialog(
      title: 'Khoản thu khác',
      catalogRoute: AdminRoute.technicalServices,
      emptyText:
          'Chưa có danh mục dịch vụ kỹ thuật. Vui lòng thêm danh mục trước.',
      noteLabel: 'Ghi chú khoản thu',
    );
    if (data == null) return;
    await createClinicalRecord(AdminRoute.payments, {
      'patient': appointment.data['patient'],
      'appointmentId': appointment.id,
      'encounterId': appointment.data['encounterId'],
      'catalogId': data['catalogId'],
      'itemType': 'BILLING',
      'note': data['note']?.isNotEmpty == true ? data['note'] : data['primary'],
      'amount': data['amount'],
      'insurancePercent': data['insurancePercent'],
      'insuranceCovered': data['insuranceCovered'],
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'Chưa thanh toán',
    }, 'Đã tạo viện phí');
  }

  Future<void> createClinicalRecord(
    AdminRoute route,
    Map<String, dynamic> data,
    String message,
  ) async {
    try {
      await widget.service.create(route, data);
      if (route != AdminRoute.payments) {
        await widget.service.loadRecords(AdminRoute.payments);
      }
      if (route != AdminRoute.serviceUsages) {
        await widget.service.loadRecords(AdminRoute.serviceUsages);
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  List<AdminRecord> activeCatalogs(AdminRoute route) {
    return widget.service.records(route).where((record) {
      final status = record.data['status']?.toString().trim().toUpperCase();
      return status == null || status.isEmpty || status == 'ACTIVE';
    }).toList();
  }

  int moneyAsInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.round();
    return int.tryParse(value.toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
  }

  double quantityAsDouble(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return 1;
    return parsed;
  }

  String formatMoney(dynamic value) {
    final number = moneyAsInt(value);
    final text = number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '${text}đ';
  }

  String catalogTitle(AdminRecord record) {
    final name = record.data['name']?.toString() ?? '';
    final code = record.data['code']?.toString() ?? '';
    final unit = record.data['unit']?.toString() ?? '';
    final price = formatMoney(record.data['price']);
    return [
      if (code.isNotEmpty) code,
      name,
      if (unit.isNotEmpty) unit,
      price,
    ].where((value) => value.isNotEmpty).join(' - ');
  }

  Future<Map<String, String>?> showCatalogOrderDialog({
    required String title,
    required AdminRoute catalogRoute,
    required String emptyText,
    required String noteLabel,
    String? noteHint,
  }) async {
    await widget.service.lookup(catalogRoute);
    if (!mounted) return null;

    final catalogs = activeCatalogs(catalogRoute);
    if (catalogs.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(emptyText),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return null;
    }

    String selectedId = catalogs.first.id;
    final quantityController = TextEditingController(text: '1');
    final insuranceController = TextEditingController(text: '0');
    final noteController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final selectedCatalog = catalogs.firstWhere(
              (item) => item.id == selectedId,
              orElse: () => catalogs.first,
            );
            final quantity = quantityAsDouble(quantityController.text);
            final unitPrice = moneyAsInt(selectedCatalog.data['price']);
            final amount = (unitPrice * quantity).round();
            final insurancePercent =
                (double.tryParse(
                          insuranceController.text.trim().replaceAll(',', '.'),
                        ) ??
                        0)
                    .clamp(0, 100)
                    .round();
            final insurancePaid = (amount * insurancePercent / 100).round();
            final patientPaid = amount - insurancePaid;

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedId,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục *',
                          border: OutlineInputBorder(),
                        ),
                        items: catalogs
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.id,
                                child: Text(
                                  catalogTitle(item),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedId = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Số lượng',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: insuranceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'BHYT thanh toán (%)',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: noteController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: noteLabel,
                          hintText: noteHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD8EADD)),
                        ),
                        child: Wrap(
                          spacing: 18,
                          runSpacing: 8,
                          children: [
                            Text('Đơn giá: ${formatMoney(unitPrice)}'),
                            Text('Thành tiền: ${formatMoney(amount)}'),
                            Text('BHYT: ${formatMoney(insurancePaid)}'),
                            Text('Người bệnh: ${formatMoney(patientPaid)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: amount <= 0
                      ? null
                      : () => Navigator.pop(dialogContext, {
                          'catalogId': selectedCatalog.id,
                          'primary':
                              selectedCatalog.data['name']?.toString() ?? '',
                          'quantity': quantity.toString(),
                          'unitPrice': unitPrice.toString(),
                          'amount': amount.toString(),
                          'insurancePercent': insurancePercent.toString(),
                          'insuranceCovered': insurancePercent > 0
                              ? 'true'
                              : 'false',
                          'note': noteController.text.trim(),
                        }),
                  child: const Text('Lưu chỉ định'),
                ),
              ],
            );
          },
        );
      },
    );

    quantityController.dispose();
    insuranceController.dispose();
    noteController.dispose();
    return result;
  }

  Future<Map<String, String>?> showQuickOrderDialog({
    required String title,
    required String primaryLabel,
    required String primaryHint,
    required String noteLabel,
    String? noteHint,
  }) async {
    final primaryController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: primaryController,
                      decoration: InputDecoration(
                        labelText: '$primaryLabel *',
                        hintText: primaryHint,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: noteLabel,
                        hintText: noteHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: primaryController.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(dialogContext, {
                          'primary': primaryController.text.trim(),
                          'note': noteController.text.trim(),
                        }),
                  child: const Text('Lưu chỉ định'),
                ),
              ],
            );
          },
        );
      },
    );
    primaryController.dispose();
    noteController.dispose();
    return result;
  }

  Future<void> showOrderPrintPreview(
    AdminRecord appointment,
    List<AdminRecord> labs,
    List<AdminRecord> imaging,
    List<AdminRecord> usages,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Phiếu chỉ định'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: SelectableText(
                [
                  'PHIẾU CHỈ ĐỊNH',
                  '',
                  'Bệnh nhân: ${appointment.data['patient'] ?? ''}',
                  'Mã bệnh nhân: ${appointment.data['patientCode'] ?? ''}',
                  'Khoa: ${appointment.data['department'] ?? ''}',
                  'Bác sĩ: ${appointment.data['doctor'] ?? ''}',
                  '',
                  'XÉT NGHIỆM',
                  ...labs.map((item) => '- ${item.data['testType'] ?? ''}'),
                  '',
                  'CHẨN ĐOÁN HÌNH ẢNH',
                  ...imaging.map((item) => '- ${item.data['title'] ?? ''}'),
                  '',
                  'DỊCH VỤ',
                  ...usages.map((item) => '- ${item.data['itemName'] ?? ''}'),
                ].join('\n'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget clinicalDetailHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required List<Widget> facts,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007A3D), Color(0xFF36A85D)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Hồ sơ nghiệp vụ' : title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.isEmpty ? 'Chưa có bệnh nhân' : subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: facts),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.isEmpty ? 'Chưa có trạng thái' : status,
              style: const TextStyle(
                color: Color(0xFF007A3D),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget detailFact(String label, dynamic value) {
    final text = value?.toString().trim() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: ${text.isEmpty ? 'Chưa có' : text}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget workflowTimeline(List<String> stages, String currentStatus) {
    final index = stages.indexOf(currentStatus);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: stages.asMap().entries.map((entry) {
          final active = entry.key == index;
          final done = index >= 0 && entry.key <= index;
          final color = done
              ? const Color(0xFF007A3D)
              : const Color(0xFFCBD5E1);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFE6F4EC) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? const Color(0xFF007A3D)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  entry.value,
                  style: TextStyle(
                    color: active
                        ? const Color(0xFF007A3D)
                        : const Color(0xFF334155),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget labIndicatorPanel(List<Map<String, dynamic>> indicators) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chỉ số xét nghiệm',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (indicators.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Chưa nhập chỉ số xét nghiệm.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF1F8F3),
                ),
                columns: const [
                  DataColumn(label: Text('Tên chỉ số')),
                  DataColumn(numeric: true, label: Text('Kết quả')),
                  DataColumn(label: Text('Đơn vị')),
                  DataColumn(label: Text('Khoảng tham chiếu')),
                  DataColumn(label: Text('Đánh giá')),
                ],
                rows: indicators.map((item) {
                  final abnormal = labIndicatorAbnormal(item);
                  final abnormalType = item['abnormalType']?.toString() ?? '';
                  final resultText = [
                    item['value']?.toString() ?? '',
                    if (abnormal) abnormalType == 'LOW' ? '↓' : '↑',
                  ].where((value) => value.isNotEmpty).join(' ');
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(item['name']?.toString() ?? ''),
                        ),
                      ),
                      DataCell(
                        Text(
                          resultText,
                          style: TextStyle(
                            color: abnormal
                                ? Colors.red.shade700
                                : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      DataCell(Text(item['unit']?.toString() ?? '')),
                      DataCell(Text(labIndicatorRange(item))),
                      DataCell(
                        statusPill(abnormal ? 'Cần lưu ý' : 'Bình thường'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget imagingPreview(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_search_outlined,
              size: 42,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 10),
            Text(
              'Chưa có hình ảnh PACS',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        absoluteUploadUrl(imageUrl),
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 250,
          alignment: Alignment.center,
          color: const Color(0xFFF8FAFC),
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget medicationPanel(List<Map<String, dynamic>> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thuốc',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Chưa có dòng thuốc.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...items.map((item) {
              final instruction = [
                item['dosage']?.toString() ?? '',
                item['instruction']?.toString() ?? '',
              ].where((value) => value.trim().isNotEmpty).join(' - ');
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.medication_outlined,
                      color: Color(0xFF007A3D),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['medicineName']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          if (instruction.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              instruction,
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    statusPill('SL ${item['quantity'] ?? ''}'),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> mapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  bool labIndicatorAbnormal(Map<String, dynamic> item) {
    if (item['abnormal'] == true) return true;
    final value = double.tryParse(item['value']?.toString() ?? '');
    final min = double.tryParse(item['normalMin']?.toString() ?? '');
    final max = double.tryParse(item['normalMax']?.toString() ?? '');
    if (value == null) return false;
    if (min != null && value < min) return true;
    if (max != null && value > max) return true;
    return false;
  }

  String labIndicatorRange(Map<String, dynamic> item) {
    final reference = item['referenceText']?.toString().trim() ?? '';
    if (reference.isNotEmpty) return reference;
    final min = item['normalMin']?.toString() ?? '';
    final max = item['normalMax']?.toString() ?? '';
    if (min.isEmpty && max.isEmpty) return 'Chưa có';
    if (min.isEmpty) return '<= $max';
    if (max.isEmpty) return '>= $min';
    return '$min - $max';
  }

  Widget detailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 22),
          ...children,
        ],
      ),
    );
  }

  Widget detailLine(String label, dynamic value) {
    final text = value?.toString().trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text.isEmpty ? 'Chưa có' : text,
              style: const TextStyle(color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  String statusText(dynamic status) {
    switch (status?.toString()) {
      case 'REQUESTED':
        return 'Chờ bệnh viện đề xuất';
      case 'PROPOSED':
        return 'Bệnh viện đã đề xuất lịch';
      case 'CONFIRMED':
        return 'Bệnh nhân đã xác nhận';
      case 'CHECKED_IN':
        return 'Đã tiếp nhận';
      case 'IN_PROGRESS':
        return 'Đang khám';
      case 'COMPLETED':
        return 'Đã khám';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status?.toString() ?? '';
    }
  }

  String genderText(dynamic gender) {
    switch (gender?.toString()) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      default:
        return gender?.toString() ?? '';
    }
  }

  Widget form() {
    return ModuleForm(
      service: widget.service,
      module: widget.module,
      record: selected,
      saving: widget.service.loading,
      onCancel: () => setState(() {
        mode = ModuleMode.list;
      }),
      onSubmit: (data) async {
        if (selected == null) {
          await widget.service.create(widget.module.route, data);
        } else {
          await widget.service.update(widget.module.route, selected!.id, data);
        }
        if (!mounted) return;
        setState(() {
          mode = ModuleMode.list;
        });
      },
    );
  }

  Widget panel({
    required String title,
    required List<Widget> actions,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFBCD3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF0059A6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Color(0xFFBCD3EA))),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }

  String labelFor(String key) {
    for (final field in widget.module.fields) {
      if (field.key == key) return field.label;
    }
    const labels = {
      'patientCode': 'Mã bệnh nhân',
      'fullName': 'Họ tên',
      'phone': 'Số điện thoại',
      'email': 'Email',
      'role': 'Vai trò',
      'organization': 'Bệnh viện',
      'patient': 'Bệnh nhân',
      'doctor': 'Bác sĩ',
      'doctorName': 'Bác sĩ',
      'department': 'Khoa',
      'title': 'Tiêu đề',
      'summary': 'Mô tả ngắn',
      'category': 'Danh mục',
      'status': 'Trạng thái',
      'statusLabel': 'Trạng thái',
      'imageUrl': 'Hình ảnh',
      'publishedAt': 'Ngày đăng',
      'performedAt': 'Ngày thực hiện',
      'createdAt': 'Ngày phát sinh',
      'requestedAt': 'Ngày mong muốn',
      'appointmentAt': 'Ngày đề xuất',
      'sentAt': 'Ngày gửi',
      'prescribedAt': 'Ngày kê',
      'testType': 'Loại xét nghiệm',
      'conclusion': 'Kết luận',
      'technique': 'Kỹ thuật',
      'relationship': 'Quan hệ',
      'roomName': 'Phòng',
      'ticketNumber': 'Số thứ tự',
      'estimatedWaitMinutes': 'Thời gian chờ',
      'rating': 'Số sao',
      'amount': 'Số tiền',
      'quantity': 'Số lượng',
      'itemName': 'Tên dịch vụ',
      'usedAt': 'Ngày phát sinh',
      'code': 'Mã',
      'name': 'Tên',
      'unit': 'Đơn vị',
      'price': 'Giá',
    };
    return labels[key] ?? key;
  }

  Widget cellValue(String column, AdminRecord record) {
    final value = record.data[column]?.toString() ?? '';
    if ((widget.module.route == AdminRoute.news ||
            widget.module.route == AdminRoute.imagingResults) &&
        column == 'imageUrl') {
      return newsImage(value, compact: true);
    }
    if (column == 'content') {
      return SizedBox(
        width: 220,
        child: Text(plainContent(value), overflow: TextOverflow.ellipsis),
      );
    }
    return SizedBox(
      width: column == 'summary' ? 220 : 150,
      child: Text(
        column == 'summary' ? plainContent(value) : value,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget detailValue(AdminField field, AdminRecord record) {
    final value = record.data[field.key]?.toString() ?? '';
    if ((widget.module.route == AdminRoute.news ||
            widget.module.route == AdminRoute.imagingResults) &&
        field.key == 'imageUrl') {
      return newsImage(value, compact: false);
    }
    if (field.kind == AdminFieldKind.richText) {
      return SelectableText(plainContent(value));
    }
    return Text(value);
  }

  Widget newsImage(String value, {required bool compact}) {
    final size = compact ? 48.0 : 280.0;
    if (value.isEmpty) {
      return Container(
        width: size,
        height: compact ? 48 : 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        absoluteUploadUrl(value),
        width: size,
        height: compact ? 48 : 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

String absoluteUploadUrl(String value) {
  if (value.startsWith('http')) return value;
  final base = AdminConfig.apiBaseUrl.replaceFirst('/api/v1', '');
  return '$base$value';
}

String plainContent(String value) {
  if (value.trim().isEmpty) return '';
  try {
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return decoded
          .map((item) => item is Map ? item['insert']?.toString() ?? '' : '')
          .join()
          .trim();
    }
    if (decoded is Map && decoded['ops'] is List) {
      return (decoded['ops'] as List)
          .map((item) => item is Map ? item['insert']?.toString() ?? '' : '')
          .join()
          .trim();
    }
  } catch (_) {}
  return value;
}

class ModuleForm extends StatefulWidget {
  final AdminApiService service;
  final AdminModule module;
  final AdminRecord? record;
  final bool saving;
  final VoidCallback onCancel;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const ModuleForm({
    super.key,
    required this.service,
    required this.module,
    required this.record,
    required this.saving,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<ModuleForm> createState() => _ModuleFormState();
}

class _ModuleFormState extends State<ModuleForm> {
  final Map<String, TextEditingController> controllers = {};
  final Map<String, String> relationIds = {};
  List<AdminRecord> organizations = [];
  List<AdminRecord> patients = [];
  List<AdminRecord> departments = [];
  List<AdminRecord> doctors = [];
  bool loadingLookups = true;

  @override
  void initState() {
    super.initState();
    for (final field in widget.module.fields) {
      controllers[field.key] = TextEditingController(
        text: widget.record?.data[field.key]?.toString() ?? '',
      );
    }
    loadLookups();
  }

  Future<void> loadLookups() async {
    final needsOrganization = widget.module.fields.any(
      (f) => f.kind == AdminFieldKind.organization,
    );
    final needsPatient = widget.module.fields.any(
      (f) => f.kind == AdminFieldKind.patient,
    );
    final needsDepartment = widget.module.fields.any(
      (f) => f.kind == AdminFieldKind.department,
    );
    final needsDoctor = widget.module.fields.any(
      (f) => f.kind == AdminFieldKind.doctor,
    );

    final loadedOrganizations = needsOrganization
        ? await widget.service.lookup(AdminRoute.organizations)
        : <AdminRecord>[];
    final loadedPatients = needsPatient
        ? await widget.service.lookup(AdminRoute.patients)
        : <AdminRecord>[];
    final loadedDepartments = needsDepartment
        ? await widget.service.lookup(AdminRoute.departments)
        : <AdminRecord>[];
    final loadedDoctors = needsDoctor
        ? await widget.service.lookup(AdminRoute.doctors)
        : <AdminRecord>[];

    if (!mounted) return;
    setState(() {
      organizations = loadedOrganizations;
      patients = loadedPatients;
      departments = loadedDepartments;
      doctors = loadedDoctors;
      loadingLookups = false;
    });
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    final data = <String, dynamic>{};
    for (final field in widget.module.fields) {
      data[field.key] = controllers[field.key]!.text.trim();
    }
    if (widget.module.route == AdminRoute.news) {
      data['contentFormat'] = 'delta';
      if ((data['publishedAt']?.toString() ?? '').isEmpty) {
        data['publishedAt'] = DateTime.now().toIso8601String();
      }
    }
    data.addAll(relationIds);
    await widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.record != null;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            editing
                ? 'Sửa ${widget.module.singular}'
                : 'Thêm ${widget.module.singular}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth > 760;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: widget.module.fields.map((field) {
                  final width = field.multiline || !twoColumns
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 16) / 2;
                  return SizedBox(width: width, child: input(field));
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: widget.saving ? null : widget.onCancel,
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: widget.saving ? null : submit,
                child: widget.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lưu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget input(AdminField field) {
    if (loadingLookups &&
        (field.kind == AdminFieldKind.patient ||
            field.kind == AdminFieldKind.organization ||
            field.kind == AdminFieldKind.department ||
            field.kind == AdminFieldKind.doctor)) {
      return const LinearProgressIndicator();
    }

    switch (field.kind) {
      case AdminFieldKind.organization:
        return relationDropdown(
          field,
          records: organizations,
          idKey: 'organizationId',
          labelBuilder: organizationLabel,
        );
      case AdminFieldKind.patient:
        return relationDropdown(
          field,
          records: patients,
          idKey: 'patientId',
          labelBuilder: patientLabel,
        );
      case AdminFieldKind.department:
        return relationDropdown(
          field,
          records: departments,
          idKey: 'departmentId',
          labelBuilder: departmentLabel,
        );
      case AdminFieldKind.doctor:
        return relationDropdown(
          field,
          records: filteredDoctors(),
          idKey: 'doctorId',
          labelBuilder: doctorLabel,
        );
      case AdminFieldKind.date:
        return dateInput(field, withTime: false);
      case AdminFieldKind.dateTime:
        return dateInput(field, withTime: true);
      case AdminFieldKind.file:
        return fileInput(field);
      case AdminFieldKind.richText:
        return richTextInput(field);
      case AdminFieldKind.timeline:
        return timelineInput(field);
      case AdminFieldKind.medicineItems:
        return medicineInput(field);
      case AdminFieldKind.number:
        return textInput(field, keyboardType: TextInputType.number);
      case AdminFieldKind.text:
        break;
    }

    if (field.options != null) {
      return DropdownButtonFormField<String>(
        initialValue: controllers[field.key]!.text.isEmpty
            ? null
            : controllers[field.key]!.text,
        decoration: InputDecoration(
          labelText: field.required ? '${field.label} *' : field.label,
          border: const OutlineInputBorder(),
        ),
        items: field.options!
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) {
          controllers[field.key]!.text = value ?? '';
        },
      );
    }

    return textInput(field);
  }

  Widget textInput(AdminField field, {TextInputType? keyboardType}) {
    return TextField(
      controller: controllers[field.key],
      keyboardType: keyboardType,
      minLines: field.multiline ? 4 : 1,
      maxLines: field.multiline ? 8 : 1,
      decoration: InputDecoration(
        labelText: field.required ? '${field.label} *' : field.label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  List<AdminRecord> filteredDoctors() {
    final department = controllers['department']?.text.trim() ?? '';
    if (department.isEmpty) return doctors;
    return doctors
        .where((doctor) => doctor.data['department'] == department)
        .toList();
  }

  Widget relationDropdown(
    AdminField field, {
    required List<AdminRecord> records,
    required String idKey,
    required String Function(AdminRecord) labelBuilder,
  }) {
    final current = controllers[field.key]!.text;
    AdminRecord? initial;
    for (final record in records) {
      if (labelBuilder(record) == current) {
        initial = record;
        relationIds[idKey] = record.id;
        break;
      }
    }

    return DropdownButtonFormField<String>(
      initialValue: initial?.id,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: field.required ? '${field.label} *' : field.label,
        border: const OutlineInputBorder(),
      ),
      items: records.map((record) {
        return DropdownMenuItem(
          value: record.id,
          child: Text(labelBuilder(record)),
        );
      }).toList(),
      onChanged: (value) {
        final selected = records.firstWhere((record) => record.id == value);
        controllers[field.key]!.text = labelBuilder(selected);
        relationIds[idKey] = selected.id;
        if (field.kind == AdminFieldKind.department) {
          controllers['doctor']?.clear();
          relationIds.remove('doctorId');
        }
        setState(() {});
      },
    );
  }

  String patientLabel(AdminRecord record) {
    final code = record.data['patientCode']?.toString() ?? '';
    final name = record.data['fullName']?.toString() ?? '';
    final phone = record.data['phone']?.toString() ?? '';
    return [code, name, phone].where((item) => item.isNotEmpty).join(' - ');
  }

  String organizationLabel(AdminRecord record) {
    final code = record.data['code']?.toString() ?? '';
    final name = record.data['name']?.toString() ?? '';
    return [code, name].where((item) => item.isNotEmpty).join(' - ');
  }

  String departmentLabel(AdminRecord record) {
    return record.data['name']?.toString() ?? '';
  }

  String doctorLabel(AdminRecord record) {
    final name = record.data['fullName']?.toString() ?? '';
    final title = record.data['title']?.toString() ?? '';
    return title.isEmpty ? name : '$name - $title';
  }

  Widget dateInput(AdminField field, {required bool withTime}) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: now,
          firstDate: DateTime(1900),
          lastDate: DateTime(now.year + 10),
        );
        if (pickedDate == null) return;

        var picked = pickedDate;
        if (withTime) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time == null) return;
          picked = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            time.hour,
            time.minute,
          );
        }

        controllers[field.key]!.text = picked.toIso8601String();
        setState(() {});
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: field.required ? '${field.label} *' : field.label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_month),
        ),
        child: Text(
          controllers[field.key]!.text.isEmpty
              ? 'Chọn ${field.label.toLowerCase()}'
              : controllers[field.key]!.text,
        ),
      ),
    );
  }

  Widget fileInput(AdminField field) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: field.required ? '${field.label} *' : field.label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              controllers[field.key]!.text.isEmpty
                  ? 'Chưa chọn file'
                  : controllers[field.key]!.text,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
                withData: true,
              );
              final file = result?.files.single;
              if (file == null) return;
              if (file.bytes == null) return;
              final upload = await widget.service.uploadFile(
                fileName: file.name,
                bytes: file.bytes!,
              );
              controllers[field.key]!.text =
                  upload['fileUrl']?.toString() ?? file.name;
              setState(() {});
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Chọn file'),
          ),
        ],
      ),
    );
  }

  Widget richTextInput(AdminField field) {
    final textController = TextEditingController(
      text: plainContent(controllers[field.key]!.text),
    );

    void persist(String value) {
      controllers[field.key]!.text = jsonEncode([
        {'insert': value.endsWith('\n') ? value : '$value\n'},
      ]);
    }

    void wrapSelection(String before, String after) {
      final selection = textController.selection;
      final text = textController.text;
      final start = selection.start < 0 ? text.length : selection.start;
      final end = selection.end < 0 ? text.length : selection.end;
      final selected = start == end ? '' : text.substring(start, end);
      final next = text.replaceRange(start, end, '$before$selected$after');
      textController.text = next;
      textController.selection = TextSelection.collapsed(
        offset: start + before.length + selected.length,
      );
      persist(next);
      setState(() {});
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => wrapSelection('**', '**'),
                child: const Text('B'),
              ),
              OutlinedButton(
                onPressed: () => wrapSelection('_', '_'),
                child: const Text('I'),
              ),
              OutlinedButton(
                onPressed: () => wrapSelection('<u>', '</u>'),
                child: const Text('U'),
              ),
              OutlinedButton(
                onPressed: () => wrapSelection('\n## ', '\n'),
                child: const Text('H'),
              ),
              OutlinedButton(
                onPressed: () => wrapSelection('\n- ', ''),
                child: const Text('⬢ List'),
              ),
              OutlinedButton(
                onPressed: () => wrapSelection('\n1. ', ''),
                child: const Text('1. List'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: textController,
            minLines: 8,
            maxLines: 16,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Nhập nội dung bài viết...',
            ),
            onChanged: persist,
          ),
        ],
      ),
    );
  }

  Widget timelineInput(AdminField field) {
    return structuredListInput(
      field,
      emptyItem: {'status': 'SCHEDULED', 'timeLabel': '', 'note': ''},
      labels: const {
        'status': 'Trạng thái',
        'timeLabel': 'Thời gian',
        'note': 'Ghi chú',
      },
    );
  }

  Widget medicineInput(AdminField field) {
    return structuredListInput(
      field,
      emptyItem: {'medicineName': '', 'dosage': '', 'quantity': '', 'note': ''},
      labels: const {
        'medicineName': 'Tên thuốc',
        'dosage': 'Liều dùng',
        'quantity': 'Số lượng',
        'note': 'Ghi chú',
      },
    );
  }

  Widget structuredListInput(
    AdminField field, {
    required Map<String, String> emptyItem,
    required Map<String, String> labels,
  }) {
    List<Map<String, String>> items;
    try {
      final parsed = jsonDecode(controllers[field.key]!.text);
      items = parsed is List
          ? parsed
                .map(
                  (item) => Map<String, String>.from(
                    (item as Map).map(
                      (key, value) =>
                          MapEntry(key.toString(), value?.toString() ?? ''),
                    ),
                  ),
                )
                .toList()
          : <Map<String, String>>[];
    } catch (_) {
      items = <Map<String, String>>[];
    }

    void persist() {
      controllers[field.key]!.text = jsonEncode(items);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCBD5E1)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: labels.entries.map((label) {
                        return SizedBox(
                          width: 180,
                          child: TextFormField(
                            initialValue: item[label.key] ?? '',
                            decoration: InputDecoration(
                              labelText: label.value,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              item[label.key] = value;
                              persist();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      items.removeAt(index);
                      persist();
                      setState(() {});
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: () {
              items.add({...emptyItem});
              persist();
              setState(() {});
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm dòng'),
          ),
        ],
      ),
    );
  }
}
