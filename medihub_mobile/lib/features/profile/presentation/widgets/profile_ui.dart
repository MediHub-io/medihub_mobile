import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;

  const ProfileHeader({
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

class ProfilePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const ProfilePrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

InputDecoration profileInputDecoration(
  String label, {
  String? hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    floatingLabelStyle: const TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.bold,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: AppColors.primary,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(
        color: AppColors.error,
      ),
    ),
  );
}