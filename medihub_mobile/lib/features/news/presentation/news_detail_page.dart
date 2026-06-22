import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../data/news_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import 'widgets/news_header.dart';

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
          await NewsService().getNewsById(widget.id);

      if (!mounted) return;

      setState(() {
        news = result;
        loading = false;
      });
    } catch (e) {
      debugPrint('DETAIL NEWS ERROR = $e');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  List<dynamic> _justifyDeltaJson(
    String rawContent,
  ) {
    try {
      final decoded = jsonDecode(rawContent);

      if (decoded is List) {
        return _justifyOps(decoded);
      }
    } catch (_) {
      return _plainTextToJustifiedDelta(rawContent);
    }

    return _plainTextToJustifiedDelta(rawContent);
  }

  List<dynamic> _justifyOps(
    List<dynamic> ops,
  ) {
    final List<dynamic> result = [];

    for (final op in ops) {
      if (op is! Map) {
        continue;
      }

      final insert = op['insert'];
      final attributes = op['attributes'];

      final Map<String, dynamic> baseAttributes =
          attributes is Map
              ? Map<String, dynamic>.from(attributes)
              : <String, dynamic>{};

      if (insert is String && insert.contains('\n')) {
        final parts = insert.split('\n');

        for (int i = 0; i < parts.length; i++) {
          if (parts[i].isNotEmpty) {
            result.add({
              'insert': parts[i],
              if (baseAttributes.isNotEmpty)
                'attributes': baseAttributes,
            });
          }

          if (i < parts.length - 1) {
            result.add({
              'insert': '\n',
              'attributes': {
                ...baseAttributes,
                'align': 'justify',
              },
            });
          }
        }
      } else {
        result.add({
          'insert': insert,
          if (baseAttributes.isNotEmpty)
            'attributes': baseAttributes,
        });
      }
    }

    if (result.isEmpty ||
        result.last is! Map ||
        result.last['insert'] != '\n') {
      result.add({
        'insert': '\n',
        'attributes': {
          'align': 'justify',
        },
      });
    }

    return result;
  }

  List<Map<String, dynamic>> _plainTextToJustifiedDelta(
    String text,
  ) {
    final lines = text.trim().split('\n');

    final List<Map<String, dynamic>> ops = [];

    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        ops.add({
          'insert': line.trim(),
        });
      }

      ops.add({
        'insert': '\n',
        'attributes': {
          'align': 'justify',
        },
      });
    }

    return ops;
  }

  QuillController _buildContentController(
    String content,
  ) {
    return QuillController(
      document: Document.fromJson(
        _justifyDeltaJson(content),
      ),
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );
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
            title: 'Chi tiết tin',
          ),

          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : news == null
                    ? const Center(
                        child: Text('Không tìm thấy tin'),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          14,
                          16,
                          16,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius:
                                BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              if (news!['imageUrl'] != null &&
                                  news!['imageUrl']
                                      .toString()
                                      .isNotEmpty)
                                ClipRRect(
                                  borderRadius:
                                      const BorderRadius.only(
                                    topLeft:
                                        Radius.circular(24),
                                    topRight:
                                        Radius.circular(24),
                                  ),
                                  child: Image.network(
                                    news!['imageUrl'],
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                              Padding(
                                padding:
                                    const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      news!['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight:
                                            FontWeight.bold,
                                        height: 1.25,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      DateFormatter.displayDate(
                                        news!['createdAt'],
                                      ),
                                      style: const TextStyle(
                                        color: AppColors
                                            .textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),

                                    if (news!['summary'] != null &&
                                        news!['summary']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 14),

                                      Container(
                                        width: double.infinity,
                                        padding:
                                            const EdgeInsets.all(
                                          14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors
                                              .primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          news!['summary'],
                                          textAlign:
                                              TextAlign.justify,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            height: 1.4,
                                            fontStyle:
                                                FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 16),

                                    IgnorePointer(
                                      child: DefaultTextStyle(
                                        style: const TextStyle(
                                          color: AppColors
                                              .textPrimary,
                                          fontSize: 14.5,
                                          height: 1.45,
                                        ),
                                        child: QuillEditor.basic(
                                          controller:
                                              _buildContentController(
                                            news!['content'] ?? '',
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
        ],
      ),
    );
  }
}
