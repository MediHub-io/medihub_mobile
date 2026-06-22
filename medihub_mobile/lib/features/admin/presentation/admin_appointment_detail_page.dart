import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/medihub_card.dart';
import '../../../shared/widgets/medihub_page.dart';
import '../data/admin_appointment_service.dart';
import 'widgets/admin_propose_appointment_dialog.dart';

class AdminAppointmentDetailPage extends StatefulWidget {
  final String appointmentId;

  const AdminAppointmentDetailPage({super.key, required this.appointmentId});

  @override
  State<AdminAppointmentDetailPage> createState() =>
      _AdminAppointmentDetailPageState();
}

class _AdminAppointmentDetailPageState
    extends State<AdminAppointmentDetailPage> {
  final service = AdminAppointmentService();

  bool loading = true;
  Map<String, dynamic>? appointment;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    try {
      final data = await service.getAppointmentDetail(widget.appointmentId);

      if (!mounted) return;

      setState(() {
        appointment = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  String statusText(String? status) {
    switch (status) {
      case 'REQUESTED':
        return 'Yêu cầu mới';
      case 'PROPOSED':
        return 'Đã đề xuất';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'COMPLETED':
        return 'Đã khám';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status ?? '';
    }
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'REQUESTED':
        return AppColors.warning;
      case 'PROPOSED':
        return AppColors.proposed;
      case 'CONFIRMED':
        return AppColors.success;
      case 'COMPLETED':
        return AppColors.completed;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> showProposeDialog(Map<String, dynamic> item) async {
    await showDialog(
      context: context,
      builder: (_) {
        return AdminProposeAppointmentDialog(
          appointment: item,
          service: service,
          onProposed: loadDetail,
        );
      },
    );
  }

  Widget statusBanner(Map<String, dynamic> item) {
    final status = item['status']?.toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor(status).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: statusColor(status)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              statusText(status),
              style: TextStyle(
                color: statusColor(status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Chưa cập nhật' : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget section(String title, List<Widget> children) {
    return MediHubCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget actions(Map<String, dynamic> item) {
    final status = item['status']?.toString();

    if (status == 'REQUESTED') {
      return actionButton(
        icon: Icons.schedule,
        label: 'Đề xuất lịch khám',
        color: AppColors.primary,
        onPressed: () => showProposeDialog(item),
      );
    }

    if (status == 'PROPOSED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Đang chờ bệnh nhân xác nhận lịch đề xuất trên mobile.',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const MediHubPage(
        title: 'Chi tiết lịch khám',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final item = appointment;

    if (item == null) {
      return const MediHubPage(
        title: 'Chi tiết lịch khám',
        child: Center(child: Text('Không tải được lịch khám')),
      );
    }

    final patient = item['patient'] is Map ? item['patient'] as Map : null;

    return MediHubPage(
      title: 'Chi tiết lịch khám',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            statusBanner(item),
            const SizedBox(height: 14),
            section('Thông tin bệnh nhân', [
              infoRow(
                Icons.person_outline,
                'Họ tên',
                item['patientName']?.toString() ?? '',
              ),
              infoRow(
                Icons.qr_code_rounded,
                'Mã bệnh nhân',
                item['patientCode']?.toString() ?? '',
              ),
              infoRow(
                Icons.phone_outlined,
                'Số điện thoại',
                item['patientPhone']?.toString() ?? '',
              ),
              infoRow(
                Icons.calendar_month_outlined,
                'Ngày sinh',
                DateFormatter.displayDate(
                  patient?['dob'] ?? item['patientDob'],
                ),
              ),
            ]),
            section('Yêu cầu của bệnh nhân', [
              infoRow(
                Icons.event_outlined,
                'Ngày mong muốn',
                DateFormatter.displayDate(item['requestedDate']),
              ),
              infoRow(
                Icons.apartment_outlined,
                'Chuyên khoa đã chọn',
                item['department']?.toString() ?? '',
              ),
              infoRow(
                Icons.medical_services_outlined,
                'Bác sĩ đã chọn',
                item['doctorName']?.toString() ?? '',
              ),
              infoRow(
                Icons.notes_outlined,
                'Lý do / triệu chứng',
                item['note']?.toString() ?? '',
              ),
            ]),
            if (item['appointmentDate'] != null)
              section('Lịch bệnh viện đề xuất', [
                infoRow(
                  Icons.event_available_outlined,
                  'Ngày giờ khám',
                  DateFormatter.displayDate(item['appointmentDate']),
                ),
                infoRow(
                  Icons.apartment_outlined,
                  'Khoa',
                  item['department']?.toString() ?? '',
                ),
                infoRow(
                  Icons.medical_services_outlined,
                  'Bác sĩ',
                  item['doctorName']?.toString() ?? '',
                ),
              ]),
            if (item['medicalRecord'] != null)
              section('Kết quả khám', [
                infoRow(
                  Icons.fact_check_outlined,
                  'Chẩn đoán',
                  item['medicalRecord']['diagnosis'] ?? '',
                ),
                infoRow(
                  Icons.assignment_turned_in_outlined,
                  'Kết luận',
                  item['medicalRecord']['conclusion'] ?? '',
                ),
                infoRow(
                  Icons.medication_outlined,
                  'Hướng điều trị',
                  item['medicalRecord']['note'] ?? '',
                ),
              ]),
            actions(item),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
