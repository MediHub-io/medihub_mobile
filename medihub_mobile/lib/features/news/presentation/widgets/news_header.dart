import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class NewsHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;

  const NewsHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xFF8DD33F),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              if (showBackButton)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF99D83F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      context.pop();
                    },
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                )
              else
                const SizedBox(width: 44),

              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }
}