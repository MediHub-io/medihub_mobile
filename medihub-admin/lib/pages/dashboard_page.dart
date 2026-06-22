import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';
import '../core/admin_models.dart';

class DashboardPage extends StatelessWidget {
  final AdminApiService service;
  final ValueChanged<AdminRoute> onOpenModule;

  const DashboardPage({
    super.key,
    required this.service,
    required this.onOpenModule,
  });

  static const blue = Color(0xFF005AA8);
  static const border = Color(0xFFC8D6E3);

  Map<String, dynamic> section(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }

  int number(Map<String, dynamic> data, String key) {
    return int.tryParse('${data[key] ?? 0}') ?? 0;
  }

  bool canOpen(AdminRoute route) {
    final role = service.adminRole;
    if (role == 'ADMIN' || role == 'SUPER_ADMIN') return true;
    final allowed = <String, Set<AdminRoute>>{
      'RECEPTIONIST': {
        AdminRoute.appointments,
        AdminRoute.reception,
        AdminRoute.queueTickets,
        AdminRoute.visits,
      },
      'DOCTOR': {
        AdminRoute.visits,
        AdminRoute.outpatient,
        AdminRoute.serviceOrders,
        AdminRoute.prescriptions,
        AdminRoute.surgeries,
        AdminRoute.inpatient,
      },
      'NURSE': {
        AdminRoute.encounters,
        AdminRoute.inpatient,
        AdminRoute.admissions,
        AdminRoute.surgeries,
      },
      'LAB_TECHNICIAN': {AdminRoute.labResults},
      'RAD_TECHNICIAN': {AdminRoute.imagingResults},
      'PHARMACIST': {AdminRoute.prescriptions, AdminRoute.medicines},
      'CASHIER': {AdminRoute.billingInvoices, AdminRoute.payments},
      'ACCOUNTANT': {AdminRoute.billingInvoices, AdminRoute.payments},
      'INSURANCE_STAFF': {AdminRoute.insuranceClaims},
    };
    return allowed[role]?.contains(route) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final data = service.hisDashboard();
    final kpis = section(data, 'kpis');
    final pipeline = section(data, 'pipeline');
    final cls = section(data, 'cls');
    final billing = section(data, 'billing');
    final inpatient = section(data, 'inpatient');
    final alerts = section(data, 'alerts');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('KPI hôm nay'),
        Row(
          children: [
            _kpi(
              'Chờ tiếp nhận',
              number(kpis, 'waitingReception'),
              AdminRoute.reception,
              const Color(0xFFF59E0B),
            ),
            _kpi(
              'Chờ khám',
              number(kpis, 'waitingExam'),
              AdminRoute.queueTickets,
              const Color(0xFFEA580C),
            ),
            _kpi(
              'Đang khám',
              number(kpis, 'inExam'),
              AdminRoute.visits,
              const Color(0xFF2563EB),
            ),
            _kpi(
              'Hoàn tất',
              number(kpis, 'completed'),
              AdminRoute.visits,
              const Color(0xFF16803C),
            ),
            _kpi(
              'Chờ thanh toán',
              number(kpis, 'waitingPayment'),
              AdminRoute.billingInvoices,
              const Color(0xFFDC2626),
            ),
            _kpi(
              'Nội trú',
              number(kpis, 'inpatient'),
              AdminRoute.inpatient,
              const Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _panel('Pipeline ngoại trú', AdminRoute.visits, _pipeline(pipeline)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: width,
                  child: _panel(
                    'Cận lâm sàng',
                    AdminRoute.labResults,
                    _metricRows([
                      (
                        'Xét nghiệm chờ lấy mẫu',
                        number(cls, 'labWaitingSample'),
                      ),
                      (
                        'Xét nghiệm chờ duyệt',
                        number(cls, 'labWaitingApproval'),
                      ),
                      (
                        'CĐHA chờ thực hiện',
                        number(cls, 'imagingWaitingPerform'),
                      ),
                      ('CĐHA chờ đọc', number(cls, 'imagingWaitingRead')),
                    ]),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _panel(
                    'Viện phí',
                    AdminRoute.billingInvoices,
                    _metricRows([
                      ('Chưa thanh toán', number(billing, 'unpaid')),
                      ('Đã thanh toán', number(billing, 'paid')),
                      (
                        'Doanh thu hôm nay',
                        number(billing, 'todayRevenue'),
                        true,
                      ),
                      ('BHYT trả', number(billing, 'insurancePay'), true),
                      ('BN trả', number(billing, 'patientPay'), true),
                    ]),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _panel(
                    'Nội trú',
                    AdminRoute.inpatient,
                    _metricRows([
                      ('Đang điều trị', number(inpatient, 'treating')),
                      ('Giường sử dụng', number(inpatient, 'occupiedBeds')),
                      ('Giường trống', number(inpatient, 'availableBeds')),
                      ('Chờ ra viện', number(inpatient, 'waitingDischarge')),
                    ]),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _panel(
                    'Cảnh báo vận hành',
                    AdminRoute.visits,
                    _metricRows([
                      (
                        'Hồ sơ thiếu chẩn đoán',
                        number(alerts, 'missingDiagnosis'),
                      ),
                      (
                        'Phiếu chưa thanh toán',
                        number(alerts, 'unpaidInvoices'),
                      ),
                      ('CLS chưa duyệt', number(alerts, 'unapprovedCls')),
                      ('BHYT lỗi', number(alerts, 'insuranceErrors')),
                    ], alert: true),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF17324D),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _kpi(String label, int value, AdminRoute route, Color color) {
    return Expanded(
      child: InkWell(
        onTap: canOpen(route) ? () => onOpenModule(route) : null,
        child: Container(
          height: 66,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: const BorderSide(color: border),
              right: const BorderSide(color: border),
              bottom: const BorderSide(color: border),
              left: BorderSide(color: color, width: 4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF526577),
                ),
              ),
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel(String title, AdminRoute route, Widget content) {
    return InkWell(
      onTap: canOpen(route) ? () => onOpenModule(route) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 30,
              color: blue,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 17,
                  ),
                ],
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }

  Widget _pipeline(Map<String, dynamic> values) {
    final stages = [
      ('Tiếp nhận', 'reception'),
      ('Hàng đợi', 'queue'),
      ('Khám', 'exam'),
      ('CLS', 'cls'),
      ('Viện phí', 'billing'),
      ('Hoàn tất', 'complete'),
    ];
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          for (var index = 0; index < stages.length; index++) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${number(values, stages[index].$2)}',
                    style: const TextStyle(
                      color: blue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    stages[index].$1,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (index < stages.length - 1)
              const Icon(
                Icons.arrow_forward,
                size: 16,
                color: Color(0xFF91A4B5),
              ),
          ],
        ],
      ),
    );
  }

  Widget _metricRows(List<dynamic> rows, {bool alert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        children: rows.map((row) {
          final values = row as dynamic;
          final label = values.$1 as String;
          final value = values.$2 as int;
          final money = values is (String, int, bool) ? values.$3 : false;
          return Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE6EDF3))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: const TextStyle(fontSize: 12)),
                ),
                Text(
                  money ? _currency(value) : '$value',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: alert && value > 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF17324D),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _currency(int value) {
    final text = '$value'.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return '${text}đ';
  }
}
