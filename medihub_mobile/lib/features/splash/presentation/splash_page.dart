import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Icon(
              Icons.local_hospital_rounded,
              size: 80,
              color: AppColors.primary,
            ),

            SizedBox(height: 24),

            Text(
              'MediHub',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.dark,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Kết nối sức khỏe – Nâng tầm chăm sóc',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}