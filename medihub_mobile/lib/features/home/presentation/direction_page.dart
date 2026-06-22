import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../../profile/presentation/widgets/profile_ui.dart';

class DirectionPage extends StatelessWidget {
  const DirectionPage({super.key});

  static const address =
      'Bệnh viện Đa khoa tỉnh Hà Tĩnh - Số 75, đường Hải Thượng Lãn Ông, phường Thành Sen, tỉnh Hà Tĩnh';

  @override
  Widget build(BuildContext context) {
    final query = Uri.encodeComponent(address);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 0),
      body: Column(
        children: [
          const ProfileHeader(title: 'Chỉ đường'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Điểm đến',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(address),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          'https://maps.googleapis.com/maps/api/staticmap?center=$query&zoom=15&size=640x360&markers=color:green%7C$query',
                          height: 240,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 240,
                              color: AppColors.primaryLight,
                              alignment: Alignment.center,
                              child: const Text(
                                'Bản đồ Google Maps đến bệnh viện',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SelectableText(
                        'https://www.google.com/maps/search/?api=1&query=$query',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
