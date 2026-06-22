import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/medihub_page.dart';
import '../data/admin_appointment_service.dart';
import 'widgets/admin_propose_appointment_dialog.dart';

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({super.key});

  @override
  State<AdminAppointmentsPage> createState() => _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState extends State<AdminAppointmentsPage> {
  final service = AdminAppointmentService();
  final searchController = TextEditingController();

  List<dynamic> appointments = [];
  bool loading = true;
  String selectedStatus = 'ALL';

  static const statuses = [
    'ALL',
    'REQUESTED',
    'PROPOSED',
    'CONFIRMED',
    'COMPLETED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
    });

    try {
      final result = await service.getAppointments(
        status: selectedStatus,
        search: searchController.text,
      );

      if (!mounted) return;

      setState(() {
        appointments = result;
        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Color statusColor(String status) {
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

  String statusText(String status) {
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
        return status;
    }
  }

  Future<void> showProposeDialog(Map<String, dynamic> item) async {
    await showDialog(
      context: context,
      builder: (_) {
        return AdminProposeAppointmentDialog(
          appointment: item,
          service: service,
          onProposed: () {
            loadData();
          },
        );
      },
    );
  }

  Widget filterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Tìm tên, mã bệnh nhân hoặc số điện thoại',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: loadData,
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => loadData(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Lọc trạng thái',
              border: OutlineInputBorder(),
            ),
            items: statuses.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status == 'ALL' ? 'Tất cả' : statusText(status)),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedStatus = value;
              });
              loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget appointmentCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? '';
    final patientName = item['patientName']?.toString();
    final patientCode = item['patientCode']?.toString();
    final patientPhone = item['patientPhone']?.toString();
    final department = item['department']?.toString();
    final doctor = item['doctorName']?.toString();
    final note = item['note']?.toString();

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        await context.push('/admin/appointment/${item['id']}');
        await loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: statusColor(status).withValues(alpha: 0.14),
                  child: Icon(Icons.calendar_month, color: statusColor(status)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName == null || patientName.isEmpty
                            ? 'Bệnh nhân'
                            : patientName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (patientCode != null && patientCode.isNotEmpty)
                            patientCode,
                          if (patientPhone != null && patientPhone.isNotEmpty)
                            patientPhone,
                        ].join(' • '),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                statusChip(status),
              ],
            ),
            const SizedBox(height: 14),
            infoLine(
              Icons.event_outlined,
              'Ngày mong muốn',
              DateFormatter.displayDate(item['requestedDate']),
            ),
            infoLine(
              Icons.apartment_outlined,
              'Chuyên khoa',
              department == null || department.isEmpty
                  ? 'Chưa chọn'
                  : department,
            ),
            infoLine(
              Icons.medical_services_outlined,
              'Bác sĩ',
              doctor == null || doctor.isEmpty ? 'Chưa chọn' : doctor,
            ),
            infoLine(
              Icons.notes_outlined,
              'Lý do khám',
              note == null || note.isEmpty ? 'Không có' : note,
            ),
            if (status == 'REQUESTED') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showProposeDialog(item),
                  icon: const Icon(Icons.schedule),
                  label: const Text('Đề xuất lịch khám'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor(status).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        statusText(status),
        style: TextStyle(
          color: statusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget infoLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediHubPage(
      title: 'Quản lý lịch khám',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: filterPanel(),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadData,
                    child: appointments.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(24),
                            children: const [
                              SizedBox(height: 80),
                              Icon(
                                Icons.event_busy_outlined,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 12),
                              Center(child: Text('Không có lịch khám phù hợp')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: appointments.length,
                            itemBuilder: (context, index) {
                              return appointmentCard(
                                Map<String, dynamic>.from(
                                  appointments[index] as Map,
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
