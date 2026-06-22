import 'package:flutter/material.dart';

import 'admin_api_service.dart';
import 'admin_models.dart';

class AdminShell extends StatelessWidget {
  final AdminApiService service;
  final AdminRoute route;
  final ValueChanged<AdminRoute> onRouteChanged;
  final Widget child;

  const AdminShell({
    super.key,
    required this.service,
    required this.route,
    required this.onRouteChanged,
    required this.child,
  });

  static const hisBlue = Color(0xFF005AA8);
  static const hisBlueDark = Color(0xFF004681);
  static const adminRoles = {'ADMIN', 'SUPER_ADMIN'};

  bool get isAdministrator => adminRoles.contains(service.adminRole);

  bool canSee(_MenuEntry entry) {
    return isAdministrator || entry.roles.contains(service.adminRole);
  }

  List<_MenuGroup> get visibleGroups => _menuGroups
      .map(
        (group) =>
            _MenuGroup(group.label, group.entries.where(canSee).toList()),
      )
      .where((group) => group.entries.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      body: Column(
        children: [
          _topNavigation(),
          _moduleHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(6),
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _statusFooter(),
    );
  }

  Widget _topNavigation() {
    return Material(
      color: hisBlue,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 38,
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.local_hospital, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'MediHub HIS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, color: Color(0x55FFFFFF)),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: visibleGroups.map(_menuGroup).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuGroup(_MenuGroup group) {
    final active = group.entries.any((entry) => entry.route == route);
    if (group.entries.length == 1) {
      final entry = group.entries.first;
      return InkWell(
        onTap: () => onRouteChanged(entry.route),
        child: _menuLabel(group.label, active, false),
      );
    }
    return PopupMenuButton<AdminRoute>(
      tooltip: group.label,
      offset: const Offset(0, 38),
      onSelected: onRouteChanged,
      itemBuilder: (context) => group.entries
          .map(
            (entry) => PopupMenuItem(
              value: entry.route,
              height: 34,
              child: Row(
                children: [
                  Icon(entry.icon, color: hisBlue, size: 17),
                  const SizedBox(width: 8),
                  Text(entry.label, style: const TextStyle(fontSize: 12.5)),
                ],
              ),
            ),
          )
          .toList(),
      child: _menuLabel(group.label, active, true),
    );
  }

  Widget _menuLabel(String label, bool active, bool dropdown) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? hisBlueDark : Colors.transparent,
        border: active
            ? const Border(bottom: BorderSide(color: Colors.white, width: 2))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (dropdown)
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 17),
        ],
      ),
    );
  }

  Widget _moduleHeader() {
    final matches = adminModules.where((module) => module.route == route);
    final title = route == AdminRoute.dashboard
        ? 'Trung tâm điều hành bệnh viện'
        : route == AdminRoute.surgeries
        ? 'Phẫu thuật / Thủ thuật'
        : route == AdminRoute.medicalTimeline
        ? 'Timeline y khoa'
        : route == AdminRoute.insuranceClaims
        ? 'Hồ sơ bảo hiểm y tế'
        : matches.isEmpty
        ? 'MediHub HIS'
        : matches.first.title;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFB8CCE0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.chevron_right, color: hisBlue, size: 18),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF15324B),
            ),
          ),
          const Spacer(),
          Text(
            service.organizationName.isEmpty
                ? service.organizationCode
                : service.organizationName,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: const Color(0xFFE8F2FB),
            child: Text(
              service.adminRole,
              style: const TextStyle(
                color: hisBlue,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            visualDensity: VisualDensity.compact,
            onPressed: service.logout,
            icon: const Icon(Icons.logout, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _statusFooter() {
    return Container(
      height: 24,
      color: const Color(0xFF15324B),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 7, color: Color(0xFF42D37B)),
          const SizedBox(width: 5),
          Text(
            service.adminPhone,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          const Spacer(),
          const Text(
            'MediHub Hospital Information System',
            style: TextStyle(color: Color(0xFFBFD1E0), fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup {
  final String label;
  final List<_MenuEntry> entries;

  const _MenuGroup(this.label, this.entries);
}

class _MenuEntry {
  final AdminRoute route;
  final String label;
  final IconData icon;
  final Set<String> roles;

  const _MenuEntry(this.route, this.label, this.icon, this.roles);
}

const _reception = {'RECEPTIONIST'};
const _doctor = {'DOCTOR'};
const _nurse = {'NURSE'};
const _lab = {'LAB_TECHNICIAN'};
const _imaging = {'RAD_TECHNICIAN'};
const _pharmacy = {'PHARMACIST'};
const _billing = {'CASHIER', 'ACCOUNTANT'};
const _insurance = {'INSURANCE_STAFF'};
const _doctorNurse = {'DOCTOR', 'NURSE'};

const _menuGroups = <_MenuGroup>[
  _MenuGroup('Tổng quan', [
    _MenuEntry(AdminRoute.dashboard, 'Dashboard', Icons.dashboard_outlined, {
      'RECEPTIONIST',
      'DOCTOR',
      'NURSE',
      'LAB_TECHNICIAN',
      'RAD_TECHNICIAN',
      'PHARMACIST',
      'CASHIER',
      'ACCOUNTANT',
      'INSURANCE_STAFF',
    }),
  ]),
  _MenuGroup('Hồ sơ y khoa', [
    _MenuEntry(
      AdminRoute.medicalTimeline,
      'Timeline y khoa',
      Icons.timeline_outlined,
      {
        'RECEPTIONIST',
        'DOCTOR',
        'NURSE',
        'LAB_TECHNICIAN',
        'RAD_TECHNICIAN',
        'PHARMACIST',
        'CASHIER',
        'ACCOUNTANT',
        'INSURANCE_STAFF',
      },
    ),
  ]),
  _MenuGroup('Tiếp nhận', [
    _MenuEntry(
      AdminRoute.appointments,
      'Lịch hẹn',
      Icons.event_outlined,
      _reception,
    ),
    _MenuEntry(
      AdminRoute.reception,
      'Tiếp nhận',
      Icons.how_to_reg_outlined,
      _reception,
    ),
    _MenuEntry(
      AdminRoute.queueTickets,
      'Hàng đợi',
      Icons.format_list_numbered,
      _reception,
    ),
  ]),
  _MenuGroup('Khám ngoại trú', [
    _MenuEntry(
      AdminRoute.visits,
      'Phòng khám',
      Icons.medical_information_outlined,
      _doctor,
    ),
    _MenuEntry(
      AdminRoute.outpatient,
      'Bệnh án ngoại trú',
      Icons.assignment_outlined,
      _doctor,
    ),
    _MenuEntry(
      AdminRoute.serviceOrders,
      'Chỉ định',
      Icons.playlist_add_check,
      _doctor,
    ),
    _MenuEntry(
      AdminRoute.prescriptions,
      'Kê đơn',
      Icons.medication_outlined,
      _doctor,
    ),
  ]),
  _MenuGroup('Cận lâm sàng', [
    _MenuEntry(
      AdminRoute.labResults,
      'Xét nghiệm',
      Icons.science_outlined,
      _lab,
    ),
    _MenuEntry(
      AdminRoute.imagingResults,
      'Chẩn đoán hình ảnh',
      Icons.image_search_outlined,
      _imaging,
    ),
    _MenuEntry(
      AdminRoute.surgeries,
      'Thủ thuật',
      Icons.medical_services_outlined,
      _doctorNurse,
    ),
  ]),
  _MenuGroup('Viện phí', [
    _MenuEntry(
      AdminRoute.billingInvoices,
      'Thu viện phí',
      Icons.point_of_sale_outlined,
      _billing,
    ),
    _MenuEntry(
      AdminRoute.payments,
      'Hóa đơn / Bảng kê',
      Icons.receipt_long_outlined,
      _billing,
    ),
  ]),
  _MenuGroup('Nội trú', [
    _MenuEntry(
      AdminRoute.inpatient,
      'Danh sách nội trú',
      Icons.bed_outlined,
      _nurse,
    ),
    _MenuEntry(
      AdminRoute.rooms,
      'Buồng giường',
      Icons.meeting_room_outlined,
      _nurse,
    ),
    _MenuEntry(
      AdminRoute.admissions,
      'Ra viện',
      Icons.exit_to_app_outlined,
      _nurse,
    ),
  ]),
  _MenuGroup('Điều dưỡng', [
    _MenuEntry(
      AdminRoute.encounters,
      'Sinh hiệu',
      Icons.monitor_heart_outlined,
      _nurse,
    ),
    _MenuEntry(
      AdminRoute.inpatient,
      'Nội trú / Y lệnh',
      Icons.assignment_turned_in_outlined,
      _nurse,
    ),
  ]),
  _MenuGroup('Phẫu thuật/Thủ thuật', [
    _MenuEntry(
      AdminRoute.surgeries,
      'Lịch và biên bản PTTT',
      Icons.local_hospital_outlined,
      _doctorNurse,
    ),
  ]),
  _MenuGroup('Dược', [
    _MenuEntry(
      AdminRoute.medicines,
      'Danh mục thuốc',
      Icons.inventory_2_outlined,
      _pharmacy,
    ),
    _MenuEntry(
      AdminRoute.prescriptions,
      'Cấp phát thuốc',
      Icons.medication_liquid_outlined,
      _pharmacy,
    ),
  ]),
  _MenuGroup('BHYT', [
    _MenuEntry(
      AdminRoute.insuranceClaims,
      'Hồ sơ BHYT / XML 4210 / Hồ sơ lỗi',
      Icons.health_and_safety_outlined,
      _insurance,
    ),
  ]),
  _MenuGroup('Danh mục', [
    _MenuEntry(
      AdminRoute.departments,
      'Khoa phòng',
      Icons.account_tree_outlined,
      {},
    ),
    _MenuEntry(AdminRoute.rooms, 'Phòng', Icons.meeting_room_outlined, {}),
    _MenuEntry(AdminRoute.beds, 'Giường', Icons.bed_outlined, {}),
    _MenuEntry(AdminRoute.doctors, 'Bác sĩ', Icons.badge_outlined, {}),
    _MenuEntry(
      AdminRoute.technicalServices,
      'Dịch vụ',
      Icons.medical_services_outlined,
      {},
    ),
    _MenuEntry(AdminRoute.medicines, 'Thuốc', Icons.medication_outlined, {}),
    _MenuEntry(AdminRoute.supplies, 'Vật tư', Icons.inventory_outlined, {}),
    _MenuEntry(AdminRoute.examFees, 'Giá', Icons.price_change_outlined, {}),
  ]),
  _MenuGroup('Truyền thông', [
    _MenuEntry(AdminRoute.news, 'Tin tức', Icons.article_outlined, {}),
    _MenuEntry(
      AdminRoute.notifications,
      'Thông báo',
      Icons.notifications_outlined,
      {},
    ),
    _MenuEntry(AdminRoute.guides, 'Hướng dẫn', Icons.help_outline, {}),
  ]),
  _MenuGroup('Phân quyền', [
    _MenuEntry(
      AdminRoute.accounts,
      'Tài khoản và vai trò',
      Icons.admin_panel_settings_outlined,
      {},
    ),
  ]),
];
