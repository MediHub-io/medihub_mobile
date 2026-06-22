import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../data/news_service.dart';
import 'widgets/news_header.dart';

class NewsListPage extends StatefulWidget {
  const NewsListPage({super.key});

  @override
  State<NewsListPage> createState() =>
      _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  final service = NewsService();

  final controller = ScrollController();

  List<dynamic> news = [];

  bool loading = false;

  bool hasMore = true;

  int page = 1;

  @override
  void initState() {
    super.initState();

    loadNews();

    controller.addListener(() {
      if (controller.position.pixels >=
          controller.position.maxScrollExtent - 300) {
        loadNews();
      }
    });
  }

  Future<void> loadNews() async {
    if (loading || !hasMore) {
      return;
    }

    loading = true;

    try {
      final result =
          await service.getNews(page: page, limit: 10);

      final List items = result['data'];

      if (!mounted) return;

      setState(() {
        news.addAll(items);

        page++;

        hasMore = page <= result['totalPages'];
      });
    } catch (e) {
      debugPrint('LOAD NEWS ERROR = $e');
    } finally {
      loading = false;
    }
  }

  Widget newsCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          context.push('/news/${item['id']}');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              item['imageUrl'] != null &&
                      item['imageUrl'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item['imageUrl'],
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.article,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      (() {
                        final date = DateTime.tryParse(
                          item['createdAt']?.toString() ?? '',
                        );

                        if (date == null) {
                          return '';
                        }

                        return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
                      })(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      item['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      item['summary'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
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
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const MainBottomNavigation(
        currentIndex: 0,
      ),
      body: Column(
        children: [
          const NewsHeader(
            title: 'Tin tức',
          ),

          Expanded(
            child: news.isEmpty && loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.only(
                      top: 12,
                      bottom: 16,
                    ),
                    itemCount:
                        news.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == news.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child:
                                CircularProgressIndicator(),
                          ),
                        );
                      }

                      return newsCard(news[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
