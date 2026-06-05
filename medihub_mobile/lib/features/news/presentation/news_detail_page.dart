import 'package:flutter/material.dart';

import '../data/news_service.dart';

import 'dart:convert';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_quill/flutter_quill.dart';

class NewsDetailPage extends StatefulWidget {
  final String id;

  const NewsDetailPage({
    super.key,
    required this.id,
  });

  @override
  State<NewsDetailPage> createState() =>
      _NewsDetailPageState();
}

class _NewsDetailPageState
    extends State<NewsDetailPage> {

  Map<String, dynamic>? news;

  bool loading = true;

  @override
  void initState() {
    super.initState();

    loadNews();
  }

  Future<void> loadNews() async {
    try {

      final result =
          await NewsService()
              .getNewsById(
        widget.id,
      );

      debugPrint(
        result['content'].toString(),
        );

      if (!mounted) return;

      setState(() {
        news = result;
        loading = false;
      });

    } catch (e) {

      debugPrint(
        'DETAIL NEWS ERROR = $e',
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
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

  leading: Padding(
    padding:
        const EdgeInsets.all(8),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
      ),
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color:
              AppColors.primary,
          size: 18,
        ),
        onPressed: () {
          Navigator.pop(
            context,
          );
        },
      ),
    ),
  ),

  title: const Text(
    'Chi tiết tin',
    style: TextStyle(
      fontWeight:
          FontWeight.bold,
    ),
  ),
),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : news == null
              ? const Center(
                  child:
                      Text('Không tìm thấy tin'),
                )
              : Container(
    color:
        AppColors.background,
    child:
        SingleChildScrollView(
      padding:
          const EdgeInsets.all(
        16,
      ),
      child: Container(
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
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [

            if (news!['imageUrl'] !=
                    null &&
                news!['imageUrl']
                    .toString()
                    .isNotEmpty)

              ClipRRect(
                borderRadius:
                    const BorderRadius.only(
                  topLeft:
                      Radius.circular(
                    24,
                  ),
                  topRight:
                      Radius.circular(
                    24,
                  ),
                ),
                child:
                    Image.network(
                  news!['imageUrl'],
                  width:
                      double.infinity,
                  height: 260,
                  fit:
                      BoxFit.cover,
                ),
              ),

            Padding(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [

                  Text(
                    news!['title'] ??
                        '',
                    style:
                        const TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    news!['createdAt']
                        .toString()
                        .substring(
                          0,
                          10,
                        ),
                    style:
                        const TextStyle(
                      color:
                          AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  if (news!['summary'] !=
                          null &&
                      news!['summary']
                          .toString()
                          .isNotEmpty)

                    Container(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.primaryLight,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: Text(
                        news!['summary'],
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontStyle:
                              FontStyle.italic,
                        ),
                      ),
                    ),

                  const SizedBox(
                    height: 24,
                  ),

                  Padding(
  padding:
      const EdgeInsets.all(8),
  child: IgnorePointer(
    child: QuillEditor.basic(
      controller: QuillController(
        document: Document.fromJson(
          jsonDecode(
            news!['content'],
          ),
        ),
        selection:
            const TextSelection.collapsed(
          offset: 0,
        ),
      ),
    ),
  ),
),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
    );
  }
}