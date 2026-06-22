import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../data/profile_service.dart';
import 'widgets/profile_ui.dart';

class RelativesPage extends StatefulWidget {
  const RelativesPage({super.key});

  @override
  State<RelativesPage> createState() => _RelativesPageState();
}

class _RelativesPageState extends State<RelativesPage> {
  bool loading = true;
  List<dynamic> relatives = [];

  @override
  void initState() {
    super.initState();
    loadRelatives();
  }

  Future<void> loadRelatives() async {
    try {
      final result = await ProfileService().getRelatives();

      if (!mounted) return;

      setState(() {
        relatives = result['data'] ?? [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> openForm(
    Map<String, dynamic>? relative,
  ) async {
    await context.push(
      '/profile/relatives/form',
      extra: relative,
    );

    await loadRelatives();
  }

  Widget _addButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Tooltip(
        message: 'Thêm người thân',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              openForm(null);
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primary,
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _relativeCard(
    Map<String, dynamic> item,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          14,
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
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item['fullName'] ?? '',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  '${item['relationship'] ?? ''} • ${item['phone'] ?? ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              openForm(
                Map<String, dynamic>.from(
                  item,
                ),
              );
            },
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(
        currentIndex: 3,
      ),
      body: Column(
        children: [
          const ProfileHeader(
            title: 'Người thân',
          ),

          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      16,
                      18,
                      18,
                    ),
                    children: [
                      _addButton(),

                      const SizedBox(
                        height: 16,
                      ),

                      if (relatives.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(
                            top: 32,
                          ),
                          child: Center(
                            child: Text(
                              'Chưa có người thân',
                            ),
                          ),
                        )
                      else
                        ...relatives.map(
                          (item) => _relativeCard(
                            Map<String, dynamic>.from(
                              item,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
