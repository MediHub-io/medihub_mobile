import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../data/profile_service.dart';
import 'widgets/profile_ui.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;
  bool saving = false;

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (newController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu mới không khớp'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await ProfileService().changePassword(
        currentPassword: currentController.text,
        newPassword: newController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Widget passwordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      decoration: profileInputDecoration(
        label,
        hint: hint,
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
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
          const ProfileHeader(title: 'Đổi mật khẩu'),
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
                        passwordField(
                          label: 'Mật khẩu hiện tại *',
                          hint: 'Vui lòng nhập Mật khẩu hiện tại',
                          controller: currentController,
                          visible: showCurrent,
                          toggle: () {
                            setState(() {
                              showCurrent = !showCurrent;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        passwordField(
                          label: 'Nhập mật khẩu mới *',
                          hint: 'Vui lòng nhập Mật khẩu mới',
                          controller: newController,
                          visible: showNew,
                          toggle: () {
                            setState(() {
                              showNew = !showNew;
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        passwordField(
                          label: 'Nhập lại mật khẩu mới *',
                          hint: 'Vui lòng nhập lại Mật khẩu mới',
                          controller: confirmController,
                          visible: showConfirm,
                          toggle: () {
                            setState(() {
                              showConfirm = !showConfirm;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  ProfilePrimaryButton(
                    label: saving ? 'Đang xử lý...' : 'Xác Nhận',
                    onPressed: saving ? null : submit,
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
