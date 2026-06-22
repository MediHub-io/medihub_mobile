import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../data/profile_service.dart';
import 'widgets/profile_ui.dart';

class RelativeFormPage extends StatefulWidget {
  final Map<String, dynamic>? relative;

  const RelativeFormPage({super.key, this.relative});

  @override
  State<RelativeFormPage> createState() => _RelativeFormPageState();
}

class _RelativeFormPageState extends State<RelativeFormPage> {
  final relationshipController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final citizenController = TextEditingController();
  final patientCodeController = TextEditingController();
  final insuranceController = TextEditingController();
  final ethnicController = TextEditingController();
  final nationalityController = TextEditingController(text: 'Việt Nam');
  final jobController = TextEditingController();
  final addressController = TextEditingController();
  final provinceController = TextEditingController();
  final wardController = TextEditingController();

  String gender = 'MALE';
  DateTime? dob;
  bool saving = false;

  bool get isEdit => widget.relative != null;

  @override
  void initState() {
    super.initState();

    final item = widget.relative;

    if (item != null) {
      relationshipController.text = item['relationship'] ?? '';
      fullNameController.text = item['fullName'] ?? '';
      phoneController.text = item['phone'] ?? '';
      emailController.text = item['email'] ?? '';
      citizenController.text = item['citizenId'] ?? '';
      patientCodeController.text = item['patientCode'] ?? '';
      insuranceController.text = item['insuranceNo'] ?? '';
      ethnicController.text = item['ethnic'] ?? '';
      nationalityController.text = item['nationality'] ?? 'Việt Nam';
      jobController.text = item['job'] ?? '';
      addressController.text = item['addressLine'] ?? '';
      provinceController.text = item['province'] ?? '';
      wardController.text = item['ward'] ?? '';
      gender = item['gender'] ?? 'MALE';
      dob = DateTime.tryParse(item['dob']?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    relationshipController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    citizenController.dispose();
    patientCodeController.dispose();
    insuranceController.dispose();
    ethnicController.dispose();
    nationalityController.dispose();
    jobController.dispose();
    addressController.dispose();
    provinceController.dispose();
    wardController.dispose();
    super.dispose();
  }

  String dobText() {
    if (dob == null) return '';

    return DateFormatter.displayDate(dob);
  }

  Future<void> pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      dob = picked;
    });
  }

  Map<String, dynamic> payload() {
    final data = {
      'relationship': relationshipController.text,
      'fullName': fullNameController.text,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'phone': phoneController.text,
      'email': emailController.text,
      'citizenId': citizenController.text,
      'patientCode': patientCodeController.text,
      'insuranceNo': insuranceController.text,
      'ethnic': ethnicController.text,
      'nationality': nationalityController.text,
      'job': jobController.text,
      'addressLine': addressController.text,
      'province': provinceController.text,
      'ward': wardController.text,
    };

    data.updateAll((key, value) {
      if (value is String) {
        return value.trim();
      }
      return value;
    });

    data.removeWhere((key, value) => value == null || value == '');

    return data;
  }

  Future<void> submit() async {
    setState(() {
      saving = true;
    });

    try {
      if (isEdit) {
        await ProfileService().updateRelative(
          id: widget.relative!['id'],
          data: payload(),
        );
      } else {
        await ProfileService().createRelative(payload());
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Đã cập nhật người thân' : 'Đã thêm người thân',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ProfileService().errorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Widget section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: AppColors.primary),
          ...children,
        ],
      ),
    );
  }

  Widget field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: profileInputDecoration(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 3),
      body: Column(
        children: [
          ProfileHeader(
            title: isEdit ? 'Sửa người thân' : 'Tạo người thân mới',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  section(
                    title: 'Thông tin cơ bản',
                    icon: Icons.person_outline,
                    children: [
                      Center(
                        child: Container(
                          width: 136,
                          height: 136,
                          margin: const EdgeInsets.only(bottom: 22),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 42,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      field('Quan hệ *', relationshipController),
                      field('Họ và tên *', fullNameController),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DropdownButtonFormField<String>(
                          initialValue: gender,
                          decoration: profileInputDecoration('Giới tính *'),
                          items: const [
                            DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                            DropdownMenuItem(
                              value: 'FEMALE',
                              child: Text('Nữ'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              gender = value;
                            });
                          },
                        ),
                      ),
                      InkWell(
                        onTap: pickDob,
                        child: IgnorePointer(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextField(
                              controller: TextEditingController(
                                text: dobText(),
                              ),
                              decoration: profileInputDecoration('Ngày sinh *'),
                            ),
                          ),
                        ),
                      ),
                      field('Dân tộc', ethnicController),
                      field('Quốc tịch *', nationalityController),
                      field('Mã bảo hiểm y tế', insuranceController),
                      field('Mã bệnh nhân (nếu có)', patientCodeController),
                      field('CMT/CCCD', citizenController),
                      field('Công việc hiện tại', jobController),
                    ],
                  ),
                  section(
                    title: 'Thông tin liên hệ',
                    icon: Icons.receipt_long_outlined,
                    children: [
                      field(
                        'Số điện thoại *',
                        phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      field(
                        'Email',
                        emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      field('Tỉnh/Thành phố *', provinceController),
                      field('Phường/Xã *', wardController),
                      field('Số nhà/ Đường', addressController),
                    ],
                  ),
                  ProfilePrimaryButton(
                    label: saving ? 'Đang xử lý...' : 'HOÀN TẤT',
                    onPressed: saving ? null : submit,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
