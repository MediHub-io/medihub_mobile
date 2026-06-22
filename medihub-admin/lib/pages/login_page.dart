import 'package:flutter/material.dart';

import '../core/admin_api_service.dart';

class LoginPage extends StatefulWidget {
  final AdminApiService service;

  const LoginPage({super.key, required this.service});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phoneController = TextEditingController(text: '0915221182');
  final passwordController = TextEditingController();
  String error = '';

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final ok = await widget.service.login(
      phoneController.text,
      passwordController.text,
    );
    if (!ok && mounted) {
      setState(() {
        error =
            widget.service.errorMessage ??
            'Tài khoản không có quyền truy cập Admin';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MediHub Admin',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đăng nhập quản trị dữ liệu bệnh viện',
                style: TextStyle(color: Color(0xFF64748B)),
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
              if (error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(error, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: widget.service.loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A3D),
                    foregroundColor: Colors.white,
                  ),
                  child: widget.service.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Đăng nhập'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
