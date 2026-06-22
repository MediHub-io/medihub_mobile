import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/admin_appointment_service.dart';

class AdminProposeAppointmentDialog extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final AdminAppointmentService service;
  final VoidCallback onProposed;

  const AdminProposeAppointmentDialog({
    super.key,
    required this.appointment,
    required this.service,
    required this.onProposed,
  });

  @override
  State<AdminProposeAppointmentDialog> createState() =>
      _AdminProposeAppointmentDialogState();
}

class _AdminProposeAppointmentDialogState
    extends State<AdminProposeAppointmentDialog> {
  static const timeSlots = [
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

  final noteController = TextEditingController();

  List<dynamic> specialties = [];
  List<dynamic> doctors = [];
  dynamic selectedSpecialty;
  dynamic selectedDoctor;
  DateTime? selectedDate;
  String? selectedTime;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadSpecialties();
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> loadSpecialties() async {
    try {
      final result = await widget.service.getSpecialties();
      if (!mounted) return;
      setState(() {
        specialties = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      showError('Không tải được danh mục khoa');
    }
  }

  Future<void> loadDoctors(String specialtyId) async {
    final result = await widget.service.getDoctors(specialtyId: specialtyId);
    if (!mounted) return;
    setState(() {
      doctors = result;
      selectedDoctor = null;
    });
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: selectedDate ?? DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
    });
  }

  DateTime selectedDateTime() {
    final parts = selectedTime!.split(':');
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> submit() async {
    if (selectedSpecialty == null) {
      showError('Vui lòng chọn khoa');
      return;
    }

    if (selectedDoctor == null) {
      showError('Vui lòng chọn bác sĩ');
      return;
    }

    if (selectedDate == null) {
      showError('Vui lòng chọn ngày khám');
      return;
    }

    if (selectedTime == null) {
      showError('Vui lòng chọn giờ khám');
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await widget.service.proposeAppointment(
        id: widget.appointment['id'],
        appointmentDate: selectedDateTime().toIso8601String(),
        departmentId: selectedSpecialty['id'],
        doctorId: selectedDoctor['id'],
        proposalNote: noteController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onProposed();
    } catch (e) {
      showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đề xuất lịch khám'),
      content: SizedBox(
        width: 520,
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    patientSummary(),
                    const SizedBox(height: 16),
                    specialtyField(),
                    const SizedBox(height: 12),
                    doctorField(),
                    const SizedBox(height: 12),
                    dateField(),
                    const SizedBox(height: 12),
                    const Text(
                      'Giờ khám',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    timeSlotPicker(),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú đề xuất',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: saving ? null : submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: Text(saving ? 'Đang đề xuất...' : 'Đề xuất'),
        ),
      ],
    );
  }

  Widget patientSummary() {
    final item = widget.appointment;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['patientName'] ?? 'Bệnh nhân',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Mã: ${item['patientCode'] ?? ''}'),
          Text('SĐT: ${item['patientPhone'] ?? ''}'),
        ],
      ),
    );
  }

  Widget specialtyField() {
    return DropdownButtonFormField<dynamic>(
      initialValue: selectedSpecialty,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Khoa/Chuyên khoa',
        border: OutlineInputBorder(),
      ),
      items: specialties.map((item) {
        return DropdownMenuItem(value: item, child: Text(item['name'] ?? ''));
      }).toList(),
      onChanged: (value) async {
        if (value == null) return;
        setState(() {
          selectedSpecialty = value;
          doctors = [];
          selectedDoctor = null;
        });
        await loadDoctors(value['id']);
      },
    );
  }

  Widget doctorField() {
    return DropdownButtonFormField<dynamic>(
      initialValue: selectedDoctor,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Bác sĩ',
        border: OutlineInputBorder(),
      ),
      items: doctors.map((item) {
        final title = item['title']?.toString();
        final name = item['fullName'] ?? '';
        return DropdownMenuItem(
          value: item,
          child: Text(title == null || title.isEmpty ? name : '$name - $title'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedDoctor = value;
        });
      },
    );
  }

  Widget dateField() {
    return InkWell(
      onTap: pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ngày khám',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_month),
        ),
        child: Text(
          selectedDate == null
              ? 'Chọn ngày khám'
              : DateFormatter.displayDate(selectedDate),
        ),
      ),
    );
  }

  Widget timeSlotPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: timeSlots.map((slot) {
        final selected = selectedTime == slot;
        return ChoiceChip(
          label: Text(slot),
          selected: selected,
          selectedColor: AppColors.primaryLight,
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
          onSelected: (_) {
            setState(() {
              selectedTime = slot;
            });
          },
        );
      }).toList(),
    );
  }
}
