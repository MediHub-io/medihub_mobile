import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class MainBottomNavigation
    extends StatelessWidget {

  final int currentIndex;

  const MainBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [

          _item(
            context,
            index: 0,
            icon:
                Icons.home_outlined,
            label:
                'Trang chủ',
            route:
                '/home',
          ),

          _item(
            context,
            index: 1,
            icon:
                Icons.calendar_month_outlined,
            label:
                'Lịch khám',
            route:
                '/appointments',
          ),

          _item(
            context,
            index: 2,
            icon:
                Icons.chat_outlined,
            label:
                'Tư vấn',
            route:
                '/consult',
          ),

          _item(
            context,
            index: 3,
            icon:
                Icons.person_outline,
            label:
                'Cá nhân',
            route:
                '/profile',
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required String route,
  }) {

    final selected =
        currentIndex ==
            index;

    return InkWell(
      borderRadius:
          BorderRadius.circular(
        18,
      ),
      onTap: () {

        if (!selected) {
          context.go(
            route,
          );
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration:
            selected
                ? BoxDecoration(
                    color:
                        AppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  )
                : null,
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [

            Icon(
              icon,
              color:
                  selected
                      ? AppColors.primary
                      : AppColors
                          .textSecondary,
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                color:
                    selected
                        ? AppColors.primary
                        : AppColors
                            .textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}