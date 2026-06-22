import 'package:flutter/material.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../../profile/presentation/widgets/profile_ui.dart';
import '../data/utility_service.dart';

class HotlinePage extends StatefulWidget {
  const HotlinePage({super.key});

  @override
  State<HotlinePage> createState() => _HotlinePageState();
}

class _HotlinePageState extends State<HotlinePage> {
  final service = UtilityService();
  String hotline = '';
  String appointmentPhone = '';
  String fullName = '';
  String phone = '';
  bool loading = true;
  bool requesting = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await service.getHotline();
    final name = await SecureStorage.getFullName();
    final userPhone = await SecureStorage.getPhone();
    if (!mounted) return;
    setState(() {
      hotline = data['hotline'] ?? '';
      appointmentPhone = data['appointmentPhone'] ?? '';
      fullName = name ?? '';
      phone = userPhone ?? '';
      loading = false;
    });
  }

  Future<void> requestCallback() async {
    setState(() {
      requesting = true;
    });
    try {
      await service.requestCallback(phone: phone, fullName: fullName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ghi nhận yêu cầu gọi lại')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi yêu cầu gọi lại')),
      );
    } finally {
      if (mounted) {
        setState(() {
          requesting = false;
        });
      }
    }
  }

  Widget row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.phone, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w500,
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
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 0),
      body: Column(
        children: [
          const ProfileHeader(title: 'Tổng đài'),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              row('Hotline', hotline),
                              const Divider(color: AppColors.primaryLight),
                              row('Đặt khám', appointmentPhone),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ProfilePrimaryButton(
                          label: requesting
                              ? 'Đang gửi yêu cầu...'
                              : 'Yêu cầu gọi lại ngay',
                          onPressed: requesting ? null : requestCallback,
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
