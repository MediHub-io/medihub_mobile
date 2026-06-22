import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/notification_service.dart';

class NotificationBadgeIcon extends StatefulWidget {
  final VoidCallback onPressed;
  final Color iconColor;
  final Duration refreshInterval;

  const NotificationBadgeIcon({
    super.key,
    required this.onPressed,
    this.iconColor = Colors.white,
    this.refreshInterval = const Duration(seconds: 20),
  });

  @override
  State<NotificationBadgeIcon> createState() => _NotificationBadgeIconState();
}

class _NotificationBadgeIconState extends State<NotificationBadgeIcon> {
  final service = NotificationService();
  Timer? timer;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    loadUnreadCount();
    timer = Timer.periodic(widget.refreshInterval, (_) => loadUnreadCount());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await service.unreadCount();
      if (!mounted) return;
      setState(() {
        unreadCount = count;
      });
    } catch (_) {
      // Badge refresh must not block the current screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none, color: widget.iconColor),
          if (unreadCount > 0)
            Positioned(
              right: -7,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
