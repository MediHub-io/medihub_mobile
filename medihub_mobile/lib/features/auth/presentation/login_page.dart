import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../../../core/storage/secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();
}

class _LoginPageState
    extends State<LoginPage> {

  final _phoneController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _loading = false;

  Future<void> _login() async {
  try {
    setState(() {
      _loading = true;
    });

    final service = AuthService();

    final result = await service.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    final data = result['data'];

    await SecureStorage.saveToken(
      data['token'],
    );

    await SecureStorage.saveUser(
      fullName: data['fullName'],
      role: data['role'],
      organizationId: data['organizationId'],
      patientId: data['patientId'],
      patientCode: data['patientCode'],
      phone: data['phone'],
    );
    print(
      'PATIENT ID = ${data['patientId']}',
    );

    print(
      'PATIENT CODE = ${data['patientCode']}',
    );

    if (!mounted) return;

    context.go('/home');
  } on DioException catch (e) {

  if (!mounted) return;

  String message =
      'Đăng nhập thất bại';

  final data =
      e.response?.data;

  if (data is Map &&
      data['message'] != null) {
    message =
        data['message']
            .toString();
  }

  ScaffoldMessenger.of(context)
      .showSnackBar(
    SnackBar(
      backgroundColor:
          Colors.red,
      content: Text(message),
    ),
  );

} catch (e) {

  if (!mounted) return;

  ScaffoldMessenger.of(context)
      .showSnackBar(
    SnackBar(
      backgroundColor:
          Colors.red,
      content: Text(
        e.toString(),
      ),
    ),
  );
} finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(
                height: 60,
              ),

              Image.asset(
                'assets/images/logo_icon.png',
                width: 100,
              ),

              const SizedBox(
                height: 24,
              ),

              const Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              TextField(
                controller:
                    _phoneController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Số điện thoại',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              TextField(
                controller:
                    _passwordController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Mật khẩu',
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 50,
                child:
                    ElevatedButton(
                  onPressed:
                      _loading
                          ? null
                          : _login,
                  child:
                      _loading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Đăng nhập',
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}