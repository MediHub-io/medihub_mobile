import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/news_service.dart';

class NewsListPage extends StatefulWidget {
  const NewsListPage({
    super.key,
  });

  @override
  State<NewsListPage> createState() =>
      _NewsListPageState();
}

class _NewsListPageState
    extends State<NewsListPage> {

  final service = NewsService();

  final controller =
      ScrollController();

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
          await service.getNews(
        page: page,
        limit: 10,
      );

      final List items =
          result['data'];

      if (!mounted) return;

      setState(() {

        news.addAll(items);

        page++;

        hasMore =
            page <=
            result['totalPages'];
      });

    } catch (e) {

      debugPrint(
        'LOAD NEWS ERROR = $e',
      );

    } finally {

      loading = false;
    }
  }

  Widget newsCard(
  Map<String, dynamic> item,
) {
  return Container(
    margin: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius:
          BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: InkWell(
      borderRadius:
          BorderRadius.circular(24),
      onTap: () {
        context.push(
          '/news/${item['id']}',
        );
      },
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [

            item['imageUrl'] != null &&
                    item['imageUrl']
                        .toString()
                        .isNotEmpty
                ? ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    child:
                        Image.network(
                      item['imageUrl'],
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 90,
                    height: 90,
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.primaryLight,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child:
                        const Icon(
                      Icons.article,
                      size: 40,
                    ),
                  ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [

      Text(
        (() {
          final date =
              DateTime.tryParse(
            item['createdAt']
                    ?.toString() ??
                '',
          );

          if (date == null) {
            return '';
          }

          return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
        })(),
        style: const TextStyle(
          fontSize: 12,
          color:
              AppColors.textSecondary,
          fontWeight:
              FontWeight.w500,
        ),
      ),

      const SizedBox(
        height: 6,
      ),

      Text(
        item['title'] ?? '',
        maxLines: 2,
        overflow:
            TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 17,
          fontWeight:
              FontWeight.bold,
        ),
      ),

      const SizedBox(
        height: 8,
      ),

      Text(
        item['summary'] ?? '',
        maxLines: 3,
        overflow:
            TextOverflow.ellipsis,
        style: const TextStyle(
          color:
              AppColors.textSecondary,
          height: 1.4,
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(

      appBar: AppBar(
  elevation: 0,
  centerTitle: true,
  backgroundColor:
      AppColors.primary,
  foregroundColor:
      AppColors.white,
  title: const Text(
    'Tin tức',
    style: TextStyle(
      fontWeight:
          FontWeight.bold,
    ),
  ),
),

      body: news.isEmpty && loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView.builder(
              controller:
                  controller,

              itemCount:
                  news.length +
                  (hasMore ? 1 : 0),

              itemBuilder:
                  (context, index) {

                if (index ==
                    news.length) {

                  return const Padding(
                    padding:
                        EdgeInsets.all(
                      20,
                    ),
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                }

                return newsCard(
                  news[index],
                );
              },
            ),
    );
  }
}