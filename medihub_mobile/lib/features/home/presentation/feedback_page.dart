import 'package:flutter/material.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../../profile/data/profile_service.dart';
import '../../profile/presentation/widgets/profile_ui.dart';
import '../data/utility_service.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final contentController = TextEditingController();
  final service = UtilityService();
  int rating = 0;
  String fullName = '';
  String phone = '';
  String avatarUrl = '';
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final name = await SecureStorage.getFullName();
    final userPhone = await SecureStorage.getPhone();
    final patientId = await SecureStorage.getPatientId();
    String loadedAvatar = '';
    if (patientId != null) {
      try {
        final result = await ProfileService().getMe();
        loadedAvatar = result['data']['avatarUrl']?.toString() ?? '';
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      fullName = name ?? '';
      phone = userPhone ?? '';
      avatarUrl = loadedAvatar;
    });
  }

  Future<void> submit() async {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao đánh giá')),
      );
      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      await service.sendFeedback(
        rating: rating,
        fullName: fullName,
        phone: phone,
        content: contentController.text.trim(),
      );
      if (!mounted) return;
      contentController.clear();
      setState(() {
        rating = 0;
        submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã gửi đánh giá')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        submitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không thể gửi đánh giá')));
    }
  }

  Widget avatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: avatarUrl.isNotEmpty
          ? Image.network(avatarUrl, width: 58, height: 58, fit: BoxFit.cover)
          : Image.asset(
              'assets/images/logo_icon.png',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 0),
      body: Column(
        children: [
          const ProfileHeader(title: 'Bài đánh giá'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      avatar(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          fullName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final selected = index < rating;
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                        icon: Icon(
                          Icons.star,
                          size: 52,
                          color: selected
                              ? const Color(0xFFFFC107)
                              : Colors.grey,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: contentController,
                    minLines: 9,
                    maxLines: 12,
                    decoration: InputDecoration(
                      hintText: 'Đánh giá của bạn (không bắt buộc)',
                      hintStyle: const TextStyle(fontSize: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ProfilePrimaryButton(
                    label: submitting ? 'Đang gửi...' : 'Gửi đánh giá',
                    onPressed: submitting ? null : submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
