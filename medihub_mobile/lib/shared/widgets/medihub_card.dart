import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MediHubCard
    extends StatelessWidget {
  final Widget child;

  const MediHubCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 18,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.card,

        borderRadius:
            BorderRadius.circular(
          28,
        ),

        boxShadow: const [
          BoxShadow(
            color:
                AppColors.shadow,
            blurRadius: 24,
            offset:
                Offset(
              0,
              8,
            ),
          ),
        ],
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(
          22,
        ),
        child: child,
      ),
    );
  }
}