import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage.dart';
import '../data/auth_service.dart';
import '../data/organization_service.dart';

class RegisterPage extends StatefulWidget {
  final String? organizationCode;
  final String? organizationName;

  const RegisterPage({
    super.key,
    this.organizationCode,
    this.organizationName,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final organizationService = OrganizationService();
  List<Map<String, dynamic>> organizations = [];
  Map<String, dynamic>? selectedOrganization;
  bool loading = false;
  bool loadingOrganizations = true;

  @override
  void initState() {
    super.initState();
    loadOrganizations();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> loadOrganizations() async {
    try {
      final rows = await organizationService.list();
      Map<String, dynamic>? selected;
      if (widget.organizationCode != null) {
        for (final item in rows) {
          if (item['code']?.toString() == widget.organizationCode) {
            selected = item;
            break;
          }
        }
        selected ??= await organizationService.getByCode(widget.organizationCode!);
      }
      if (!mounted) return;
      setState(() {
        organizations = rows;
        selectedOrganization = selected;
        loadingOrganizations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingOrganizations = false);
    }
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

  Future<void> register() async {
    if (selectedOrganization == null) {
      showMessage('Vui lòng chọn bệnh viện');
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      showMessage('Mật khẩu nhập lại không khớp');
      return;
    }

    setState(() => loading = true);
    try {
      final result = await AuthService().register(
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
        organizationId: selectedOrganization!['id']?.toString(),
        organizationCode: selectedOrganization!['code']?.toString(),
      );
      await saveSession(Map<String, dynamic>.from(result['data'] as Map));
      if (!mounted) return;
      context.go('/home');
    } on DioException catch (error) {
      final data = error.response?.data;
      showMessage(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Đăng ký thất bại',
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lockedByQr = widget.organizationCode != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (lockedByQr)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_hospital_outlined),
                        title: Text(
                          selectedOrganization?['name']?.toString() ??
                              widget.organizationName ??
                              'Bệnh viện từ mã QR',
                        ),
                        subtitle: Text(widget.organizationCode ?? ''),
                      ),
                    )
                  else if (loadingOrganizations)
                    const LinearProgressIndicator()
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedOrganization?['id']?.toString(),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Bệnh viện',
                        border: OutlineInputBorder(),
                      ),
                      items: organizations.map((item) {
                        return DropdownMenuItem(
                          value: item['id']?.toString(),
                          child: Text(item['name']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedOrganization = organizations.firstWhere(
                            (item) => item['id']?.toString() == value,
                          );
                        });
                      },
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nhập lại mật khẩu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : register,
                      child: loading
                          ? const CircularProgressIndicator()
                          : const Text('Đăng ký'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Đã có tài khoản? Đăng nhập'),
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
