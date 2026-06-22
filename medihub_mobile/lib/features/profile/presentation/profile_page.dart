import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../data/profile_service.dart';
import 'patient_qr_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  Map<String, dynamic>? patient;
  String patientId = '';
  String patientCode = '';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final result = await ProfileService().getMe();
      final data = Map<String, dynamic>.from(result['data'] as Map);
      final resolvedPatientId = data['id']?.toString() ?? '';
      final resolvedPatientCode = data['patientCode']?.toString() ?? '';

      if (resolvedPatientId.isEmpty) {
        throw Exception('PatientId not found');
      }

      await SecureStorage.saveUser(
        fullName: data['fullName']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        role: data['user']?['role']?.toString() ?? 'PATIENT',
        organizationId: data['organizationId']?.toString() ??
            data['user']?['organizationId']?.toString() ??
            '',
        patientId: resolvedPatientId,
        patientCode: resolvedPatientCode,
      );

      if (!mounted) return;

      setState(() {
        patient = data;
        patientId = resolvedPatientId;
        patientCode = resolvedPatientCode;
        _loading = false;
      });
    } catch (e) {
      debugPrint('LOAD PROFILE ERROR = $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
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

      await ProfileService().updateMe({'avatarUrl': avatarUrl});

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

  String formatDob(dynamic value) {
    return DateFormatter.displayDate(value);
  }

  String formatGender(dynamic value) {
    if (value == 'MALE') return 'Nam';
    if (value == 'FEMALE') return 'Nữ';
    return value?.toString() ?? '';
  }

  String summaryContactText() {
    final phone = patient?['phone']?.toString() ?? '';

    if (patientCode.isEmpty) {
      return phone;
    }

    if (phone.isEmpty) {
      return patientCode;
    }

    return '$patientCode • $phone';
  }

  void showComingSoon(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title đang được phát triển')));
  }

  ImageProvider avatarImage() {
    final avatarUrl = patient?['avatarUrl']?.toString() ?? '';

    if (avatarUrl.isNotEmpty) {
      return NetworkImage(avatarUrl);
    }

    return const AssetImage('assets/images/logo_icon.png');
  }

  Widget buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 48),
              const Expanded(
                child: Text(
                  'Hồ sơ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 8),
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
                        radius: 36,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: avatarImage(),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient?['fullName'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        '${formatGender(patient?['gender'])} • ${formatDob(patient?['dob'])}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        summaryContactText(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: openQrPage,
                  icon: const Icon(
                    Icons.qr_code_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void openQrPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientQrPage(
          patientId: patientId,
          patientCode: patientCode,
          fullName: patient?['fullName'] ?? '',
          phone: patient?['phone'] ?? '',
          dob: formatDob(patient?['dob']),
        ),
      ),
    );
  }

  Widget menuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 3),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : patient == null
          ? const Center(child: Text('Không tải được hồ sơ'))
          : Container(
              color: const Color(0xFFF7F9FC),
              child: SafeArea(
                child: Column(
                  children: [
                    buildHeader(),

                    const SizedBox(height: 18),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              children: [
                                menuItem(
                                  icon: Icons.person_outline,
                                  title: 'Thông tin cá nhân',
                                  onTap: () async {
                                    await context.push('/profile/detail');

                                    await loadProfile();
                                  },
                                ),
                                menuItem(
                                  icon: Icons.group_outlined,
                                  onTap: () {
                                    context.push('/profile/relatives');
                                  },
                                  title: 'Người thân',
                                ),
                                menuItem(
                                  icon: Icons.card_giftcard_outlined,
                                  onTap: () {
                                    context.push('/profile/referral');
                                  },
                                  title: 'Giới thiệu bạn bè',
                                ),
                                menuItem(
                                  icon: Icons.policy_outlined,
                                  onTap: () {
                                    context.push('/profile/policy');
                                  },
                                  title: 'Chính sách',
                                ),
                                menuItem(
                                  icon: Icons.lock_outline,
                                  onTap: () {
                                    context.push('/profile/change-password');
                                  },
                                  title: 'Đổi mật khẩu',
                                ),
                                menuItem(
                                  icon: Icons.phone_android_outlined,
                                  onTap: () {
                                    context.push('/profile/change-phone');
                                  },
                                  title: 'Đổi số điện thoại',
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
            ),
    );
  }
}
