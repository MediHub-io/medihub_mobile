import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../../profile/presentation/widgets/profile_ui.dart';
import '../data/utility_service.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  final service = UtilityService();
  List<dynamic> guides = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await service.getGuides();
      if (!mounted) return;
      setState(() {
        guides = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        guides = [];
        loading = false;
      });
    }
  }

  Widget guideItem(Map<String, dynamic> item, int index) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(16),
            childrenPadding: const EdgeInsets.fromLTRB(98, 0, 18, 18),
            leading: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              item['title'] ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              item['content'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            children: [
              Text(
                item['content'] ?? '',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
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
          const ProfileHeader(title: 'Hướng dẫn'),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: guides.length,
                    itemBuilder: (context, index) {
                      return guideItem(
                        Map<String, dynamic>.from(guides[index]),
                        index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
