import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool codeSent = false;
  String? devCode;

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> requestCode() async {
    setState(() => loading = true);
    try {
      final result = await AuthService().requestPasswordReset(
        phone: phoneController.text.trim(),
      );
      final data = Map<String, dynamic>.from(result['data'] as Map);
      if (!mounted) return;
      setState(() {
        codeSent = true;
        devCode = data['devCode']?.toString();
      });
      showMessage('Mã xác nhận đã được tạo', isError: false);
    } on DioException catch (error) {
      final data = error.response?.data;
      showMessage(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Không lấy được mã xác nhận',
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> confirmReset() async {
    if (passwordController.text != confirmPasswordController.text) {
      showMessage('Mật khẩu nhập lại không khớp');
      return;
    }

    setState(() => loading = true);
    try {
      await AuthService().confirmPasswordReset(
        phone: phoneController.text.trim(),
        code: codeController.text.trim(),
        newPassword: passwordController.text,
      );
      if (!mounted) return;
      showMessage('Đổi mật khẩu thành công', isError: false);
      context.go('/login');
    } on DioException catch (error) {
      final data = error.response?.data;
      showMessage(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Không đổi được mật khẩu',
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : Colors.green,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !codeSent,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!codeSent)
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : requestCode,
                        child: loading
                            ? const CircularProgressIndicator()
                            : const Text('Lấy mã'),
                      ),
                    )
                  else ...[
                    if (devCode != null && devCode!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Mã test: $devCode'),
                      ),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mã xác nhận',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu mới',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nhập lại mật khẩu mới',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : confirmReset,
                        child: loading
                            ? const CircularProgressIndicator()
                            : const Text('Đổi mật khẩu'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
