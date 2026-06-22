import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../../profile/data/profile_service.dart';
import '../../profile/presentation/patient_qr_page.dart';
import '../../notifications/presentation/widgets/notification_badge_icon.dart';
import '../data/appointment_service.dart';
import 'appointment_detail_page.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final service = AppointmentService();
  final noteController = TextEditingController();

  List<dynamic> appointments = [];
  List<dynamic> specialties = [];
  List<dynamic> doctors = [];
  bool loading = true;
  bool submitting = false;
  bool loadingDoctors = false;

  String fullName = '';
  String phone = '';
  String ageText = '';
  String avatarUrl = '';
  String patientId = '';
  String patientCode = '';

  int selectedSpecialtyIndex = 0;
  int? selectedDoctorIndex;
  int selectedDateStart = 0;
  int selectedDateIndex = 0;
  String? selectedTime;

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> initData() async {
    await Future.wait([
      loadPatientHeader(),
      loadAppointments(),
      loadSpecialties(),
    ]);
  }

  Future<void> loadPatientHeader() async {
    final name = await SecureStorage.getFullName();
    final code = await SecureStorage.getPatientCode();
    final pid = await SecureStorage.getPatientId();
    final userPhone = await SecureStorage.getPhone();

    String loadedAvatarUrl = '';
    String loadedAgeText = '';

    if (pid != null) {
      try {
        final result = await ProfileService().getMe();
        final patient = result['data'];
        loadedAvatarUrl = patient['avatarUrl']?.toString() ?? '';

        if (patient['dob'] != null) {
          final dob = DateTime.tryParse(patient['dob'].toString());
          if (dob != null) {
            final now = DateTime.now();
            int age = now.year - dob.year;
            if (now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day)) {
              age--;
            }
            loadedAgeText = '$age tuổi';
          }
        }
      } catch (e) {
        debugPrint('LOAD APPOINTMENT HEADER ERROR = $e');
      }
    }

    if (!mounted) return;

    setState(() {
      fullName = name ?? '';
      phone = userPhone ?? '';
      patientCode = code ?? '';
      patientId = pid ?? '';
      avatarUrl = loadedAvatarUrl;
      ageText = loadedAgeText;
    });
  }

  Future<void> loadSpecialties() async {
    final data = await service.getSpecialties();

    if (!mounted) return;

    setState(() {
      specialties = data;
      selectedSpecialtyIndex = 0;
      selectedDoctorIndex = null;
      selectedTime = null;
    });

    await loadDoctors();
  }

  Future<void> loadDoctors() async {
    if (specialties.isEmpty) return;

    setState(() {
      loadingDoctors = true;
      selectedDoctorIndex = null;
      selectedTime = null;
    });

    final specialty = specialties[selectedSpecialtyIndex];
    final data = await service.getDoctors(
      specialtyId: specialty['id']?.toString(),
    );

    if (!mounted) return;

    setState(() {
      doctors = data;
      loadingDoctors = false;
    });
  }

  Future<void> loadAppointments() async {
    try {
      final result = await service.getMyAppointments();

      if (!mounted) return;

      setState(() {
        appointments = result;
        loading = false;
      });
    } catch (e) {
      debugPrint('LOAD APPOINTMENTS ERROR = $e');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  DateTime get selectedDate {
    final now = DateTime.now();
    final date = now.add(Duration(days: selectedDateStart + selectedDateIndex));
    return DateTime(date.year, date.month, date.day);
  }

  List<String> availableTimes() {
    final baseSlots = <String>[
      '08:00',
      '08:30',
      '09:00',
      '09:30',
      '10:00',
      '10:30',
      '11:00',
      '13:30',
      '14:00',
      '14:30',
      '15:00',
      '15:30',
      '16:00',
      '16:30',
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!selectedDate.isAtSameMomentAs(today)) return baseSlots;

    final threshold = now.add(const Duration(hours: 1));

    return baseSlots.where((slot) {
      final parts = slot.split(':');
      final slotTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      return slotTime.isAfter(threshold) ||
          slotTime.isAtSameMomentAs(threshold);
    }).toList();
  }

  String getStatusText(String status) {
    switch (status) {
      case 'REQUESTED':
        return 'Đang chờ xác nhận';
      case 'PROPOSED':
        return 'Bệnh viện đề xuất lịch';
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
        return status.isEmpty ? 'Lịch hẹn' : status;
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
        return AppColors.primary;
    }
  }

  String weekdayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      default:
        return 'CN';
    }
  }

  DateTime selectedDateTime() {
    final time = selectedTime ?? '08:00';
    final parts = time.split(':');
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Future<void> submitAppointment() async {
    if (specialties.isEmpty) {
      showMessage('Vui lòng chọn chuyên khoa');
      return;
    }

    if (selectedDoctorIndex == null) {
      showMessage('Vui lòng chọn bác sĩ khám');
      return;
    }

    if (selectedTime == null) {
      showMessage('Vui lòng chọn khung giờ khám');
      return;
    }

    try {
      setState(() {
        submitting = true;
      });

      await service.createAppointment(
        requestedDate: selectedDateTime(),
        note: noteController.text.trim(),
      );

      if (!mounted) return;

      noteController.clear();
      setState(() {
        selectedTime = null;
        submitting = false;
      });

      await loadAppointments();
      showMessage('Đã gửi yêu cầu đặt lịch khám');
    } catch (e) {
      debugPrint('CREATE APPOINTMENT ERROR = $e');

      if (!mounted) return;

      setState(() {
        submitting = false;
      });
      showMessage('Không thể gửi yêu cầu đặt lịch');
    }
  }

  Future<void> confirmAppointment(Map<String, dynamic> item) async {
    try {
      setState(() {
        submitting = true;
      });
      await service.confirmAppointment(item['id']);
      await loadAppointments();
      if (!mounted) return;
      showMessage('Đã xác nhận lịch khám');
    } catch (error) {
      if (!mounted) return;
      showMessage(errorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  Future<void> cancelAppointment(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        submitting = true;
      });
      await service.cancelAppointment(item['id']);
      await loadAppointments();
      if (!mounted) return;
      showMessage('Đã hủy lịch hẹn');
    } catch (error) {
      if (!mounted) return;
      showMessage(errorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  void openQrPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientQrPage(
          patientId: patientId,
          patientCode: patientCode,
          fullName: fullName,
          phone: phone,
        ),
      ),
    );
  }

  ImageProvider avatarImage() {
    if (avatarUrl.isNotEmpty) return NetworkImage(avatarUrl);
    return const AssetImage('assets/images/logo_icon.png');
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(radius: 24, backgroundImage: avatarImage()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [ageText, phone].where((item) => item.isNotEmpty).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: openQrPage,
            icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
          ),
          NotificationBadgeIcon(
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget buildBookingIntro() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lên lịch khám bệnh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Đặt lịch khám với bác sĩ chuyên khoa',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.calendar_month_outlined, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget buildSpecialtyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('Bước 1: Chọn chuyên khoa'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(specialties.length, (index) {
              final selected = index == selectedSpecialtyIndex;
              final specialty = specialties[index];

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(specialty['name']?.toString() ?? ''),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: AppColors.primaryLight,
                  backgroundColor: const Color(0xFFF3F4F6),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  ),
                  side: BorderSide.none,
                  onSelected: (_) async {
                    setState(() {
                      selectedSpecialtyIndex = index;
                    });
                    await loadDoctors();
                  },
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget buildDoctorStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('Bước 2: Chọn bác sĩ đảm nhiệm'),
        if (loadingDoctors)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (doctors.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Chưa có bác sĩ cho chuyên khoa này'),
          )
        else
          Column(
            children: List.generate(doctors.length, (index) {
              final doctor = doctors[index];
              final selected = selectedDoctorIndex == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      selectedDoctorIndex = index;
                      selectedTime = null;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor['fullName']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doctor['title']?.toString() ??
                                    'Bác sĩ chuyên khoa',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFF59E0B),
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                doctor['rating']?.toString() ?? '4.9',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget buildDateStep() {
    final dates = List.generate(7, (index) {
      final date = DateTime.now().add(
        Duration(days: selectedDateStart + index),
      );
      return DateTime(date.year, date.month, date.day);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('Bước 3: Chọn ngày khám'),
        Row(
          children: [
            if (selectedDateStart > 0)
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedDateStart = (selectedDateStart - 7).clamp(0, 365);
                    selectedDateIndex = 0;
                    selectedTime = null;
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(dates.length, (index) {
                    final date = dates[index];
                    final selected = index == selectedDateIndex;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            selectedDateIndex = index;
                            selectedTime = null;
                          });
                        },
                        child: Container(
                          width: 54,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                weekdayLabel(date),
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                date.day.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  color: selected ? Colors.white : Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  selectedDateStart += 7;
                  selectedDateIndex = 0;
                  selectedTime = null;
                });
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTimeStep() {
    if (selectedDoctorIndex == null) return const SizedBox.shrink();

    final times = availableTimes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('Bước 4: Chọn khung giờ'),
        if (times.isEmpty)
          const Text(
            'Hôm nay không còn khung giờ phù hợp. Vui lòng chọn ngày khác.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: times.map((time) {
              final selected = selectedTime == time;
              return InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () {
                  setState(() {
                    selectedTime = time;
                  });
                },
                child: Container(
                  width: 88,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    time,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget buildReasonStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle('Bước 5: Lý do & triệu chứng khám'),
        TextField(
          controller: noteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'Quý khách vui lòng mô tả ngắn gọn triệu chứng đang mắc phải để bác sĩ chuẩn bị chu đáo hơn...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildBookingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSpecialtyStep(),
          const SizedBox(height: 22),
          buildDoctorStep(),
          const SizedBox(height: 22),
          buildDateStep(),
          const SizedBox(height: 22),
          buildTimeStep(),
          if (selectedDoctorIndex != null) const SizedBox(height: 22),
          buildReasonStep(),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: submitting ? null : submitAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.72),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Đặt lịch khám ngay',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String appointmentTime(Map<String, dynamic> item) {
    final value = item['appointmentDate'] ?? item['requestedDate'];
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget buildAppointmentCard(Map<String, dynamic> item) {
    final status = item['status'] ?? '';
    final color = getStatusColor(status);
    final title = item['doctorName']?.toString().isNotEmpty == true
        ? item['doctorName'].toString()
        : getStatusText(status);
    final department = item['department']?.toString().isNotEmpty == true
        ? item['department'].toString()
        : 'Lịch khám';
    final date = item['appointmentDate'] ?? item['requestedDate'];

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetailPage(appointment: item),
          ),
        );

        if (result == true) await loadAppointments();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          department.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (appointmentTime(item).isNotEmpty) ...[
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointmentTime(item),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Ngày ${DateFormatter.displayDate(date)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if ((item['note'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '“${item['note']}”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  if (status == 'PROPOSED') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton(
                          onPressed: submitting
                              ? null
                              : () => confirmAppointment(item),
                          child: const Text('Xác nhận'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => cancelAppointment(item),
                          child: const Text('Từ chối'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hủy lịch hẹn',
              onPressed: status == 'REQUESTED' || status == 'CONFIRMED'
                  ? () => cancelAppointment(item)
                  : null,
              icon: const Icon(Icons.delete_outline),
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAppointmentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch hẹn của quý khách (${appointments.length})'.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        if (appointments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('Chưa có lịch hẹn'),
          )
        else
          ...appointments.map((item) => buildAppointmentCard(item)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        await loadAppointments();
                        await loadSpecialties();
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        children: [
                          buildBookingIntro(),
                          const SizedBox(height: 16),
                          buildBookingCard(),
                          const SizedBox(height: 24),
                          buildAppointmentsList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
