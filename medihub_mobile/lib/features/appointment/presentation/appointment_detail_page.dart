import 'package:flutter/material.dart';
import '../data/appointment_service.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import 'widgets/appointment_header.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';

String getStatusText(String status) {
  switch (status) {
    case 'REQUESTED':
      return 'Đang chờ xác nhận';
    case 'PROPOSED':
      return 'BV đề xuất lịch';
    case 'CONFIRMED':
      return 'Đã xác nhận';
    case 'CHECKED_IN':
      return 'Đã tiếp nhận';
    case 'IN_PROGRESS':
      return 'Đang khám';
    case 'COMPLETED':
      return 'Đã khám';
    case 'CANCELLED':
      return 'Đã hủy';
    default:
      return status;
  }
}

Color getStatusColor(String status) {
  switch (status) {
    case 'REQUESTED':
      return AppColors.warning;
    case 'PROPOSED':
      return AppColors.secondary;
    case 'CONFIRMED':
      return AppColors.success;
    case 'CHECKED_IN':
      return AppColors.secondary;
    case 'IN_PROGRESS':
      return AppColors.primary;
    case 'COMPLETED':
      return AppColors.textSecondary;
    case 'CANCELLED':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

class AppointmentDetailPage extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailPage({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentDetailPage> createState() =>
      _AppointmentDetailPageState();
}

class _AppointmentDetailPageState
    extends State<AppointmentDetailPage> {
  final service = AppointmentService();

  bool loading = false;
  bool detailLoading = true;
  Map<String, dynamic>? detail;

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    final data = await service.getAppointmentDetail(
      widget.appointment['id'],
    );

    if (!mounted) return;

    setState(() {
      detail = data;
      detailLoading = false;
    });
  }

  Future<void> confirm() async {
    setState(() {
      loading = true;
    });

    try {
      await service.confirmAppointment(
        widget.appointment['id'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác nhận lịch khám')),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage(error))),
      );
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> cancel() async {
    setState(() {
      loading = true;
    });

    try {
      await service.cancelAppointment(
        widget.appointment['id'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy lịch hẹn')),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage(error))),
      );
      setState(() {
        loading = false;
      });
    }
  }

  String errorMessage(Object error) {
    try {
      final dynamic e = error;
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}
    return error.toString();
  }

  Widget _softCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoBox({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isEmpty ? '--' : value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (detailLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        bottomNavigationBar: MainBottomNavigation(
          currentIndex: 1,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final appointment = detail!;
    final status = appointment['status'] ?? '';
    final medicalRecord = appointment['medicalRecord'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(
        currentIndex: 1,
      ),
      body: Column(
        children: [
          const AppointmentHeader(
            title: 'Chi tiết lịch khám',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _softCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            getStatusText(status),
                            style: TextStyle(
                              color: getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          appointment['doctorName'] ?? 'Chưa sắp xếp lịch',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appointment['department'] ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ngày khám',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                  Text(
                                    appointment['appointmentDate'] != null
                                        ? DateFormatter.displayDate(
                                            appointment['appointmentDate'],
                                          )
                                        : '--',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(
                              child: _infoBox(
                                label: 'Ngày mong muốn',
                                value: DateFormatter.displayDate(
                                  appointment['requestedDate'],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _infoBox(
                                label: 'Trạng thái',
                                value: getStatusText(status),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _softCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ghi chú',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          appointment['note']?.toString().isNotEmpty == true
                              ? appointment['note']
                              : 'Không có ghi chú',
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.3,
                          ),
                        ),
                        if (medicalRecord != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(
                              12,
                              10,
                              12,
                              10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kết quả khám',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Chẩn đoán: ${medicalRecord['diagnosis'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Kết luận: ${medicalRecord['conclusion'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Ghi chú: ${medicalRecord['note'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (status == 'PROPOSED') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading ? null : confirm,
                            child: const Text('Xác nhận'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: loading ? null : cancel,
                            child: const Text('Từ chối'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
