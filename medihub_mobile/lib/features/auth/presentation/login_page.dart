import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage.dart';
import '../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> saveSession(Map<String, dynamic> data) async {
    await SecureStorage.saveToken(data['token']?.toString() ?? '');
    await SecureStorage.saveUser(
      fullName: data['fullName']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      organizationId: data['organizationId']?.toString() ?? '',
      organizationCode: data['organizationCode']?.toString(),
      organizationName: data['organizationName']?.toString(),
      patientId: data['patientId']?.toString() ?? '',
      patientCode: data['patientCode']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
    );
  }

  Future<void> login() async {
    setState(() => loading = true);
    try {
      final result = await AuthService().login(
        phone: phoneController.text.trim(),
        password: passwordController.text,
      );
      await saveSession(Map<String, dynamic>.from(result['data'] as Map));
      if (!mounted) return;
      context.go('/home');
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Đăng nhập thất bại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/logo_icon.png', width: 96, height: 96),
                  const SizedBox(height: 22),
                  const Text(
                    'Đăng nhập',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => login(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/reset-password'),
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Đăng nhập'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Tạo tài khoản mới'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
