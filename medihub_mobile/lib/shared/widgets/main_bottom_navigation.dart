import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class MainBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const MainBottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _item(
              context,
              index: 0,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Trang chủ',
              route: '/home',
            ),
            _item(
              context,
              index: 1,
              icon: Icons.calendar_month_outlined,
              selectedIcon: Icons.calendar_month,
              label: 'Lịch khám',
              route: '/appointments',
            ),
            _item(
              context,
              index: 2,
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              label: 'Tư vấn',
              route: '/consult',
            ),
            _item(
              context,
              index: 3,
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Cá nhân',
              route: '/profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String route,
  }) {
    final selected = currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        if (!selected) {
          context.go(route);
        }
      },
      child: Container(
        width: 86,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: selected
            ? BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
