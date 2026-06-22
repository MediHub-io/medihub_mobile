import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../../location/data/location_service.dart';
import '../data/profile_service.dart';
import 'widgets/profile_ui.dart';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({super.key});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  List<dynamic> provinces = [];
  List<dynamic> wards = [];

  dynamic selectedProvince;
  dynamic selectedWard;

  bool _loading = true;
  bool isEditing = false;
  bool saving = false;

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final citizenController = TextEditingController();
  final ethnicController = TextEditingController();
  final nationalityController = TextEditingController();
  final insuranceController = TextEditingController();

  DateTime? dob;
  String gender = 'MALE';
  Map<String, dynamic>? patient;

  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    citizenController.dispose();
    ethnicController.dispose();
    nationalityController.dispose();
    insuranceController.dispose();
    super.dispose();
  }

  Future<void> initData() async {
    await loadProfile();
    await loadProvinces();
  }

  Future<void> loadProvinces() async {
    final service = LocationService();
    final result = await service.getProvinces();

    debugPrint('PROVINCES COUNT = ${result.length}');
    if (result.isNotEmpty) {
      debugPrint('FIRST PROVINCE = ${result.first}');
    }

    provinces = result;

    if (patient != null) {
      try {
        debugPrint('DB PROVINCE = ${patient!['province']}');
        selectedProvince = provinces.firstWhere(
          (p) => p['name'] == patient!['province'],
        );

        debugPrint('RESTORED PROVINCE = ${selectedProvince['name']}');

        final service = LocationService();
        wards = await service.getWardsByProvince(selectedProvince['code']);

        selectedWard = wards.firstWhere((w) => w['name'] == patient!['ward']);
      } catch (e) {
        debugPrint('RESTORE LOCATION ERROR = $e');
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> uploadAvatar() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      final patientId = await SecureStorage.getPatientId();
      if (patientId == null) return;

      final fileName =
          '$patientId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await Supabase.instance.client.storage
            .from('avatars')
            .uploadBinary(fileName, bytes);
      } else {
        await Supabase.instance.client.storage
            .from('avatars')
            .upload(fileName, File(image.path));
      }

      final avatarUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      final service = ProfileService();

      await service.updateMe({'avatarUrl': avatarUrl});

      await loadProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh đại diện thành công')),
      );
    } catch (e, stackTrace) {
      debugPrint('UPLOAD AVATAR ERROR = $e');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> loadProfile() async {
    try {
      final service = ProfileService();
      final result = await service.getMe();

      if (!mounted) return;

      setState(() {
        patient = result['data'];
        final resolvedPatientId = patient?['id']?.toString();
        if (resolvedPatientId != null && resolvedPatientId.isNotEmpty) {
          SecureStorage.updatePatientId(resolvedPatientId);
        }
        syncFormFromPatient();
        _loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  void syncFormFromPatient() {
    final data = patient;
    if (data == null) return;

    fullNameController.text = data['fullName'] ?? '';
    phoneController.text = data['phone'] ?? '';
    citizenController.text = data['citizenId'] ?? '';
    ethnicController.text = data['ethnic'] ?? '';
    nationalityController.text = data['nationality'] ?? '';
    insuranceController.text = data['insuranceNo'] ?? '';

    dob = data['dob'] == null ? null : DateTime.tryParse(data['dob']);
    gender = data['gender'] ?? 'MALE';
  }

  Future<void> saveProfile() async {
    try {
      setState(() {
        saving = true;
      });

      final service = ProfileService();

      debugPrint(
        'SAVE DATA = ${{'fullName': fullNameController.text, 'phone': phoneController.text, 'citizenId': citizenController.text, 'ethnic': ethnicController.text, 'nationality': nationalityController.text, 'insuranceNo': insuranceController.text, 'gender': gender, 'dob': dob?.toIso8601String()}}',
      );

      await service.updateMe({
        'fullName': fullNameController.text,
        'phone': phoneController.text,
        'citizenId': citizenController.text,
        'ethnic': ethnicController.text,
        'nationality': nationalityController.text,
        'insuranceNo': insuranceController.text,
        'province': selectedProvince?['name'],
        'ward': selectedWard?['name'],
        'gender': gender,
        'dob': dob?.toIso8601String(),
      });

      await SecureStorage.updateFullName(fullNameController.text);
      await SecureStorage.updatePhone(phoneController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
      );

      setState(() {
        isEditing = false;
      });

      await loadProfile();
    } on DioException catch (e) {
      debugPrint('STATUS = ${e.response?.statusCode}');
      debugPrint('RESPONSE = ${e.response?.data}');

      String message = 'Cập nhật thất bại';
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        message = data['message'];
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      debugPrint('SAVE PROFILE ERROR = $e');
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  String genderText(dynamic value) {
    if (value == 'MALE') return 'Nam';
    if (value == 'FEMALE') return 'Nữ';
    return value?.toString() ?? '';
  }

  ImageProvider avatarImage() {
    final avatarUrl = patient?['avatarUrl']?.toString() ?? '';
    if (avatarUrl.isNotEmpty) return NetworkImage(avatarUrl);
    return const AssetImage('assets/images/logo_icon.png');
  }

  InputDecoration fieldDecoration(
    String label, {
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return profileInputDecoration(
      label,
      hint: hint,
      suffixIcon: suffixIcon,
    ).copyWith(
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget loadingView() {
    return const Expanded(
      child: Center(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget errorView() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.person_off_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Không tải được hồ sơ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng kiểm tra kết nối và thử lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                    });
                    initData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget avatarBlock() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: uploadAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: avatarImage(),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient?['fullName'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    genderText(patient?['gender']),
                    DateFormatter.displayDate(patient?['dob']),
                  ].where((item) => item.isNotEmpty).join(' • '),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  patient?['phone']?.toString() ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget infoField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? 'Chưa cập nhật' : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: value.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget editField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: fieldDecoration(label, icon: icon),
      ),
    );
  }

  Widget dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            initialDate: dob ?? DateTime(1990),
          );

          if (picked != null) {
            setState(() {
              dob = picked;
            });
          }
        },
        child: InputDecorator(
          decoration: fieldDecoration(
            'Ngày sinh',
            icon: Icons.calendar_month_outlined,
            suffixIcon: const Icon(Icons.expand_more),
          ),
          child: Text(
            dob == null ? 'Chọn ngày sinh' : DateFormatter.displayDate(dob),
            style: TextStyle(
              color: dob == null
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget genderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: gender,
        decoration: fieldDecoration('Giới tính', icon: Icons.wc_outlined),
        items: const [
          DropdownMenuItem(value: 'MALE', child: Text('Nam')),
          DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
        ],
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            gender = value;
          });
        },
      ),
    );
  }

  Widget provinceField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<dynamic>(
        initialValue: selectedProvince,
        isExpanded: true,
        decoration: fieldDecoration('Tỉnh/Thành', icon: Icons.location_city),
        items: provinces.map((p) {
          return DropdownMenuItem(value: p, child: Text(p['name']));
        }).toList(),
        onChanged: (value) async {
          setState(() {
            selectedProvince = value;
            selectedWard = null;
          });

          final service = LocationService();
          final result = await service.getWardsByProvince(
            (value as Map)['code'],
          );

          if (!mounted) return;
          setState(() {
            wards = result;
          });
        },
      ),
    );
  }

  Widget wardField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<dynamic>(
        initialValue: selectedWard,
        isExpanded: true,
        decoration: fieldDecoration('Phường/Xã', icon: Icons.place_outlined),
        items: wards.map((w) {
          return DropdownMenuItem(value: w, child: Text(w['name']));
        }).toList(),
        onChanged: (value) async {
          if (value == null) return;

          setState(() {
            selectedWard = value;
          });
        },
      ),
    );
  }

  Widget viewSections() {
    return Column(
      children: [
        section(
          title: 'Thông tin định danh',
          icon: Icons.badge_outlined,
          children: [
            infoField(
              icon: Icons.qr_code_rounded,
              label: 'Mã bệnh nhân',
              value: patient!['patientCode'] ?? '',
            ),
            infoField(
              icon: Icons.credit_card_outlined,
              label: 'CCCD',
              value: patient!['citizenId'] ?? '',
            ),
            infoField(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: patient!['phone'] ?? '',
            ),
          ],
        ),
        section(
          title: 'Thông tin cá nhân',
          icon: Icons.person_outline,
          children: [
            infoField(
              icon: Icons.account_circle_outlined,
              label: 'Họ và tên',
              value: patient!['fullName'] ?? '',
            ),
            infoField(
              icon: Icons.calendar_month_outlined,
              label: 'Ngày sinh',
              value: DateFormatter.displayDate(patient!['dob']),
            ),
            infoField(
              icon: Icons.wc_outlined,
              label: 'Giới tính',
              value: genderText(patient!['gender']),
            ),
            infoField(
              icon: Icons.groups_outlined,
              label: 'Dân tộc',
              value: patient!['ethnic'] ?? '',
            ),
            infoField(
              icon: Icons.public_outlined,
              label: 'Quốc tịch',
              value: patient!['nationality'] ?? '',
            ),
          ],
        ),
        section(
          title: 'Địa chỉ',
          icon: Icons.location_on_outlined,
          children: [
            infoField(
              icon: Icons.location_city,
              label: 'Tỉnh/Thành',
              value: patient!['province'] ?? '',
            ),
            infoField(
              icon: Icons.place_outlined,
              label: 'Phường/Xã',
              value: patient!['ward'] ?? '',
            ),
          ],
        ),
        section(
          title: 'Bảo hiểm y tế',
          icon: Icons.health_and_safety_outlined,
          children: [
            infoField(
              icon: Icons.medical_information_outlined,
              label: 'BHYT',
              value: patient!['insuranceNo'] ?? '',
            ),
          ],
        ),
      ],
    );
  }

  Widget editSections() {
    return Column(
      children: [
        section(
          title: 'Thông tin định danh',
          icon: Icons.badge_outlined,
          children: [
            infoField(
              icon: Icons.qr_code_rounded,
              label: 'Mã bệnh nhân',
              value: patient!['patientCode'] ?? '',
            ),
            editField(
              icon: Icons.credit_card_outlined,
              label: 'CCCD',
              controller: citizenController,
              keyboardType: TextInputType.number,
            ),
            editField(
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        section(
          title: 'Thông tin cá nhân',
          icon: Icons.person_outline,
          children: [
            editField(
              icon: Icons.account_circle_outlined,
              label: 'Họ và tên',
              controller: fullNameController,
            ),
            dateField(),
            genderField(),
            editField(
              icon: Icons.groups_outlined,
              label: 'Dân tộc',
              controller: ethnicController,
            ),
            editField(
              icon: Icons.public_outlined,
              label: 'Quốc tịch',
              controller: nationalityController,
            ),
          ],
        ),
        section(
          title: 'Địa chỉ',
          icon: Icons.location_on_outlined,
          children: [provinceField(), wardField()],
        ),
        section(
          title: 'Bảo hiểm y tế',
          icon: Icons.health_and_safety_outlined,
          children: [
            editField(
              icon: Icons.medical_information_outlined,
              label: 'BHYT',
              controller: insuranceController,
            ),
          ],
        ),
      ],
    );
  }

  Widget actionButtons() {
    if (!isEditing) {
      return ProfilePrimaryButton(
        label: 'Chỉnh sửa hồ sơ',
        onPressed: () {
          setState(() {
            isEditing = true;
          });
        },
      );
    }

    return Column(
      children: [
        ProfilePrimaryButton(
          label: saving ? 'Đang lưu...' : 'Lưu thay đổi',
          onPressed: saving ? null : saveProfile,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: saving
                ? null
                : () {
                    setState(() {
                      isEditing = false;
                      syncFormFromPatient();
                    });
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget content() {
    if (_loading) return loadingView();
    if (patient == null) return errorView();

    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          avatarBlock(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            child: Column(
              children: [
                isEditing ? editSections() : viewSections(),
                const SizedBox(height: 6),
                actionButtons(),
              ],
            ),
          ),
        ],
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
          const ProfileHeader(title: 'Thông tin cá nhân'),
          content(),
        ],
      ),
    );
  }
}
