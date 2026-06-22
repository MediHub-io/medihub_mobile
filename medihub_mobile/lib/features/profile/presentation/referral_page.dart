import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../data/profile_service.dart';
import 'widgets/profile_ui.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  bool loading = true;
  Map<String, dynamic>? info;

  @override
  void initState() {
    super.initState();
    loadInfo();
  }

  Future<void> loadInfo() async {
    try {
      final result = await ProfileService().getReferralInfo();

      if (!mounted) return;

      setState(() {
        info = result['data'];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ProfileService().errorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String value(String key) {
    return info?[key]?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = value('qrUrl');
    final orgName = value('organizationName');
    final logoUrl = value('logoUrl');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 3),
      body: Column(
        children: [
          const ProfileHeader(title: 'Giới thiệu bạn bè'),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width - 56,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F0FF),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Ứng dụng khách hàng',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              QrImageView(
                                data: qrUrl,
                                size: 260,
                                backgroundColor: Colors.white,
                              ),
                              Container(
                                width: 70,
                                height: 70,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: logoUrl.isEmpty
                                    ? Image.asset('assets/images/logo_icon.png')
                                    : Image.network(
                                        logoUrl,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Image.asset(
                                                  'assets/images/logo_icon.png',
                                                ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            orgName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            qrUrl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Đóng',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
