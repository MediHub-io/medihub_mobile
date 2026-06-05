import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/news_service.dart';

class NewsAdminPage extends StatefulWidget {
  const NewsAdminPage({
    super.key,
  });

  @override
  State<NewsAdminPage> createState() =>
      _NewsAdminPageState();
}

class _NewsAdminPageState
    extends State<NewsAdminPage> {

  final service = NewsService();

  List<dynamic> news = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    loadNews();
  }

  Future<void> loadNews() async {
    try {

      final result =
            await service.getNews(
            page: 1,
            limit: 100,
            );

      if (!mounted) return;

      setState(() {
        news = result['data'];
        loading = false;
      });

    } catch (e) {

      debugPrint(
        'LOAD NEWS ERROR = $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> deleteNews(
    String id,
  ) async {

    try {

      await service.deleteNews(
        id,
      );

      await loadNews();

    } catch (e) {

      debugPrint(
        'DELETE NEWS ERROR = $e',
      );
    }
  }

  @override
Widget build(
BuildContext context,
) {
return Scaffold(
backgroundColor:
AppColors.background,

appBar: AppBar(
  elevation: 0,
  centerTitle: true,
  backgroundColor:
      AppColors.primary,
  foregroundColor:
      AppColors.white,
  title: const Text(
    'Quản lý tin tức',
    style: TextStyle(
      fontWeight:
          FontWeight.bold,
    ),
  ),
),

floatingActionButton:
    FloatingActionButton(
  backgroundColor:
      AppColors.primary,
  foregroundColor:
      AppColors.white,
  onPressed: () async {

    await context.push(
      '/admin/news/create',
    );

    await loadNews();
  },
  child: const Icon(
    Icons.add,
  ),
),

body: loading
    ? const Center(
        child:
            CircularProgressIndicator(),
      )
    : news.isEmpty
        ? const Center(
            child: Text(
              'Chưa có tin tức',
            ),
          )
        : RefreshIndicator(
            onRefresh:
                loadNews,
            child:
                ListView.builder(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              itemCount:
                  news.length,
              itemBuilder:
                  (
                context,
                index,
              ) {

                final item =
                    news[index];

                return Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 16,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.card,
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color:
                            AppColors.shadow,
                        blurRadius: 20,
                        offset:
                            Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ListTile(

                    contentPadding:
                        const EdgeInsets.all(
                      16,
                    ),

                    leading:
                        item['imageUrl'] !=
                                    null &&
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
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
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

                    title: Text(
                      item['title'] ??
                          '',
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    subtitle:
                        Padding(
                      padding:
                          const EdgeInsets.only(
                        top: 8,
                      ),
                      child: Text(
                        item['createdAt']
                            .toString()
                            .substring(
                              0,
                              10,
                            ),
                      ),
                    ),

                    trailing: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [

                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                          ),
                          onPressed:
                              () async {

                            await context
                                .push(
                              '/admin/news/edit/${item['id']}',
                            );

                            await loadNews();
                          },
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color:
                                Colors.red,
                          ),
                          onPressed:
                              () async {

                            final confirm =
                                await showDialog<bool>(
                              context:
                                  context,
                              builder:
                                  (
                                context,
                              ) {
                                return AlertDialog(
                                  title:
                                      const Text(
                                    'Xóa tin tức',
                                  ),
                                  content:
                                      const Text(
                                    'Bạn chắc chắn muốn xóa?',
                                  ),
                                  actions: [

                                    TextButton(
                                      onPressed:
                                          () {
                                        Navigator.pop(
                                          context,
                                          false,
                                        );
                                      },
                                      child:
                                          const Text(
                                        'Hủy',
                                      ),
                                    ),

                                    ElevatedButton(
                                      onPressed:
                                          () {
                                        Navigator.pop(
                                          context,
                                          true,
                                        );
                                      },
                                      child:
                                          const Text(
                                        'Xóa',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm ==
                                true) {

                              await deleteNews(
                                item['id'],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

);
}
}