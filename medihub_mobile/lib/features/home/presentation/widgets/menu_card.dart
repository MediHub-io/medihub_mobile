import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MenuCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          hovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          hovering = false;
        });
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: hovering
                    ? AppColors.primaryLight.withValues(alpha: .65)
                    : widget.color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hovering ? AppColors.primary.withValues(alpha: .35) : Colors.white,
                  width: 4.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 28, color: widget.color),
            ),

            const SizedBox(height: 8),

            Text(
              widget.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
