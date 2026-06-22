import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../data/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final service = NotificationService();
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = service.list();
  }

  String formatDate(dynamic value) {
    if (value == null) return '';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd-$mm-$yyyy $hh:$min';
  }

  Future<void> reload() async {
    setState(() {
      future = service.list();
    });
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF61B83A)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
          ),
          const Expanded(
            child: Text(
              'Thông báo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget notificationCard(Map<String, dynamic> item) {
    final isRead = item['isRead'] == true;
    return InkWell(
      onTap: () async {
        await service.markRead(item['id'].toString());
        await reload();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : AppColors.primaryLight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isRead
                    ? Colors.grey.shade100
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active_outlined,
                color: isRead ? Colors.grey : AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']?.toString() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['content']?.toString() ?? '',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatDate(item['sentAt']),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 0),
      body: SafeArea(
        child: Column(
          children: [
            header(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: reload,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: const [
                          SizedBox(height: 120),
                          Icon(Icons.error_outline, size: 42, color: Colors.red),
                          SizedBox(height: 12),
                          Text(
                            'Không tải được thông báo',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      );
                    }
                    final rows = snapshot.data ?? [];
                    if (rows.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: const [
                          SizedBox(height: 120),
                          Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'Chưa có thông báo',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: rows.map(notificationCard).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
