import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../profile/presentation/patient_qr_page.dart';
import '../../../core/storage/secure_storage.dart';
import 'widgets/menu_card.dart';
import '../../profile/data/profile_service.dart';
import '../../news/data/news_service.dart';
import '../../notifications/presentation/widgets/notification_badge_icon.dart';
import '../../../core/theme/app_colors.dart';
import 'dart:async';
import '../../../shared/widgets/main_bottom_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String fullName = '';
  String role = '';
  String patientCode = '';
  String patientId = '';
  String phone = '';
  String ageText = '';
  String avatarUrl = '';
  int currentBanner = 0;
  Timer? bannerTimer;

  final PageController bannerController = PageController();

  void startBannerAutoSlide() {
    bannerTimer?.cancel();

    bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (news.isEmpty || !bannerController.hasClients) {
        return;
      }

      final total = news.length > 4 ? 4 : news.length;

      int next = currentBanner + 1;

      if (next >= total) {
        next = 0;
      }

      bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  List<dynamic> news = [];
  bool loadingNews = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final result = await NewsService().getNews(page: 1, limit: 6);

      if (!mounted) return;

      setState(() {
        news = result['data'];
        loadingNews = false;
      });

      startBannerAutoSlide();
    } catch (e) {
      debugPrint('LOAD NEWS ERROR = $e');

      if (!mounted) return;

      setState(() {
        loadingNews = false;
      });
    }
  }

  Future<void> _loadUser() async {
    final name = await SecureStorage.getFullName();

    final userRole = await SecureStorage.getRole();

    final code = await SecureStorage.getPatientCode();

    final pid = await SecureStorage.getPatientId();

    final userPhone = await SecureStorage.getPhone();

    String loadedAvatarUrl = '';

    if (pid != null) {
      final service = ProfileService();

      final result = await service.getMe();

      final patient = result['data'];
      debugPrint('DOB = ${patient['dob']}');

      loadedAvatarUrl = patient['avatarUrl']?.toString() ?? '';

      if (patient['dob'] != null) {
        final dob = DateTime.parse(patient['dob']);

        final now = DateTime.now();

        int age = now.year - dob.year;

        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }

        ageText = '$age tuổi';
      }
    }

    if (!mounted) return;

    setState(() {
      fullName = name ?? '';
      role = userRole ?? '';
      phone = userPhone ?? '';
      avatarUrl = loadedAvatarUrl;
      patientCode = code ?? '';
      patientId = pid ?? '';
    });
  }

  void showUtilityMessage(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title đang được phát triển')));
  }

  Future<void> logout() async {
    await SecureStorage.clear();

    if (!mounted) return;

    context.go('/login');
  }

  Widget buildHeader() {
    return Container(
      //margin: const EdgeInsets.all(16), //Bo góc tất cả
      //padding: const EdgeInsets.symmetric(
      //  horizontal: 16,
      //   vertical: 14,
      //  ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),

      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : const AssetImage('assets/images/logo_icon.png')
                        as ImageProvider,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '$ageText • $phone',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientQrPage(
                    patientId: patientId,
                    patientCode: patientCode,
                    fullName: fullName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
          ),

          NotificationBadgeIcon(
            onPressed: () => context.push('/notifications'),
          ),

          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget newsSlider() {
    final banners = news.take(4).toList();

    if (banners.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: bannerController,
        itemCount: banners.length,
        onPageChanged: (index) {
          setState(() {
            currentBanner = index;
          });
        },
        itemBuilder: (context, index) {
          final item = banners[index];

          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              context.push('/news/${item['id']}');
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    item['imageUrl'],
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),

                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),

                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Text(
                    item['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget newsCard(Map<String, dynamic> item) {
    final createdAt = DateTime.tryParse(item['createdAt']?.toString() ?? '');

    final dateText = createdAt == null
        ? ''
        : '${createdAt.day.toString().padLeft(2, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        context.push('/news/${item['id']}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item['imageUrl'],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.article, size: 40),
                    ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      item['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      item['summary'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bannerTimer?.cancel();

    bannerController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 0),

      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFF7F9FC)),

        child: SafeArea(
          child: Column(
            children: [
              buildHeader(),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // BANNER
                      newsSlider(),

                      const SizedBox(height: 12),

                      if (news.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            news.length > 4 ? 4 : news.length,
                            (index) {
                              final selected = currentBanner == index;

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: selected ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 8),

                      // MENU
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tiện ích',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.1,
                        children: [
                          MenuCard(
                            icon: Icons.event_note_outlined,
                            title: 'Sổ thứ tự',
                            color: AppColors.secondary,
                            onTap: () {
                              context.push('/queue');
                            },
                          ),

                          MenuCard(
                            icon: Icons.science_outlined,
                            title: 'Xét nghiệm',
                            color: Color(0xFFE53935),
                            onTap: () {
                              context.push('/lab-results');
                            },
                          ),

                          MenuCard(
                            icon: Icons.image_outlined,
                            title: 'CĐ hình ảnh',
                            color: Color(0xFF8E24AA),
                            onTap: () {
                              context.push('/imaging-results');
                            },
                          ),

                          MenuCard(
                            icon: Icons.local_hospital_outlined,
                            title: 'Phẫu thuật',
                            color: Color(0xFFFF9800),
                            onTap: () {
                              context.push('/surgery');
                            },
                          ),

                          MenuCard(
                            icon: Icons.phone_outlined,
                            title: 'Tổng đài',
                            color: const Color(0xFFE91E63),
                            onTap: () {
                              context.push('/hotline');
                            },
                          ),

                          MenuCard(
                            icon: Icons.chat_bubble_outline,
                            title: 'Góp ý',
                            color: AppColors.success,
                            onTap: () {
                              context.push('/feedback');
                            },
                          ),

                          MenuCard(
                            icon: Icons.location_on_outlined,
                            title: 'Chỉ đường',
                            color: Color(0xFF6D4C41),
                            onTap: () {
                              context.push('/direction');
                            },
                          ),

                          MenuCard(
                            icon: Icons.help_outline,
                            title: 'Hướng dẫn',
                            color: Color(0xFF546E7A),
                            onTap: () {
                              context.push('/guide');
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // NEWS HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tin tức',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              context.push('/news');
                            },
                            child: const Text('Xem thêm'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // NEWS
                      if (loadingNews)
                        const Center(child: CircularProgressIndicator())
                      else if (news.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Chưa có tin tức'),
                          ),
                        )
                      else
                        ...news.map((item) => newsCard(item)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
