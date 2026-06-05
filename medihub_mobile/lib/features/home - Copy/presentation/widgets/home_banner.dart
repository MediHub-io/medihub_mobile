import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HomeBanner extends StatelessWidget {
  const HomeBanner({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: AppColors.card,

        borderRadius:
            BorderRadius.circular(
          32,
        ),

        boxShadow: const [
          BoxShadow(
            color:
                AppColors.shadow,
            blurRadius: 30,
            spreadRadius: 2,
            offset: Offset(
              0,
              10,
            ),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        child: Image.asset(
          'assets/images/logo_green.png',
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}