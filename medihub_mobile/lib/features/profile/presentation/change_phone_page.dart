import 'package:flutter/material.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../data/profile_service.dart';
import 'widgets/profile_ui.dart';

class ChangePhonePage extends StatefulWidget {
  const ChangePhonePage({super.key});

  @override
  State<ChangePhonePage> createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends State<ChangePhonePage> {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();

  String? otpId;
  String? devCode;
  bool loading = false;

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    super.dispose();
  }

  Future<void> requestCode() async {
    setState(() {
      loading = true;
    });

    try {
      final result = await ProfileService().requestPhoneOtp(
        phoneController.text.trim(),
      );

      final data = result['data'];

      if (!mounted) return;

      setState(() {
        otpId = data['id'];
        devCode = data['devCode'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            devCode == null ? 'Đã gửi mã xác thực' : 'Mã xác thực: $devCode',
          ),
        ),
      );
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
          loading = false;
        });
      }
    }
  }

  Future<void> verifyCode() async {
    if (otpId == null) return;

    setState(() {
      loading = true;
    });

    try {
      await ProfileService().verifyPhoneOtp(
        otpId: otpId!,
        phone: phoneController.text.trim(),
        code: codeController.text.trim(),
      );

      await SecureStorage.updatePhone(phoneController.text.trim());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi số điện thoại thành công')),
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
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 3),
      body: Column(
        children: [
          const ProfileHeader(title: 'Đổi số điện thoại'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: profileInputDecoration(
                            'Số điện thoại',
                            hint: 'Vui lòng nhập Số điện thoại',
                          ),
                        ),
                        if (otpId != null) ...[
                          const SizedBox(height: 18),
                          TextField(
                            controller: codeController,
                            keyboardType: TextInputType.number,
                            decoration: profileInputDecoration(
                              'Mã xác thực',
                              hint: 'Vui lòng nhập mã xác thực',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  ProfilePrimaryButton(
                    label: loading
                        ? 'Đang xử lý...'
                        : otpId == null
                        ? 'Lấy mã'
                        : 'Xác Nhận',
                    onPressed: loading
                        ? null
                        : otpId == null
                        ? requestCode
                        : verifyCode,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
