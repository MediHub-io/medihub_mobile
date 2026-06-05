import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import '../data/news_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';

class NewsFormPage extends StatefulWidget {
  final String? newsId;

  const NewsFormPage({
    super.key,
    this.newsId,
  });

  @override
  State<NewsFormPage> createState() =>
      _NewsFormPageState();
}


class _NewsFormPageState
    extends State<NewsFormPage> {

    final service = NewsService();

    bool saving = false;
    bool loading = true;


Future<void> saveNews() async {
  try {

    setState(() {
      saving = true;
    });

    final content =
        jsonEncode(
      quillController
          .document
          .toDelta()
          .toJson(),
    );

    final payload = {
      'title':
          titleController.text,
      'summary':
          summaryController.text,
      'content': content,

      'imageUrl': imageUrl,
    };

    if (widget.newsId == null) {

      await service.createNews(
        data: payload,
      );

    } else {

      await service.updateNews(
        id: widget.newsId!,
        data: payload,
      );
    }

    if (!mounted) return;

    Navigator.pop(context);

  } catch (e) {

    debugPrint(
      'SAVE NEWS ERROR = $e',
    );

  } finally {

    if (mounted) {
      setState(() {
        saving = false;
      });
    }
  }
}


  final titleController =
      TextEditingController();

  final summaryController =
      TextEditingController();

      String? imageUrl;

        bool uploadingImage = false;

  late QuillController
      quillController;

  @override
    void initState() {
    super.initState();

    quillController =
        QuillController.basic();

    if (widget.newsId != null) {
        loadNewsDetail();
    } else {
        loading = false;
    }
    }


  Future<void> pickNewsImage() async {
  try {

    final image =
        await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      uploadingImage = true;
    });

    final fileName =
        'news-${DateTime.now().millisecondsSinceEpoch}.jpg';

    final bytes =
        await image.readAsBytes();

        await Supabase.instance.client.storage
            .from('news')
            .uploadBinary(
            fileName,
            bytes,
        );

    final url =
        Supabase.instance.client.storage
            .from('news')
            .getPublicUrl(
              fileName,
            );

    setState(() {
      imageUrl = url;
    });

  } finally {

    if (mounted) {
      setState(() {
        uploadingImage = false;
      });
    }
  }
}

Future<void> loadNewsDetail() async {
  try {

    final news =
        await service.getNewsById(
      widget.newsId!,
    );

    titleController.text =
        news['title'] ?? '';

    summaryController.text =
        news['summary'] ?? '';

    imageUrl =
        news['imageUrl'];

    if (news['content'] != null &&
        news['content']
            .toString()
            .isNotEmpty) {

      final document =
          Document.fromJson(
        jsonDecode(
          news['content'],
        ),
      );

      quillController =
          QuillController(
        document: document,
        selection:
            const TextSelection.collapsed(
          offset: 0,
        ),
      );
    }

  } catch (e) {

    debugPrint(
      'LOAD NEWS DETAIL ERROR = $e',
    );

  } finally {

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
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

  title: Text(
    widget.newsId == null
        ? 'Thêm tin tức'
        : 'Sửa tin tức',
    style: const TextStyle(
      fontWeight:
          FontWeight.bold,
    ),
  ),
        actions: [
          IconButton(
            onPressed:
                saving
                    ? null
                    : saveNews,

            icon: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(),
                    )
                : const Icon(
                    Icons.save,
                    ),
            ),
        ],
      ),
      body: loading
? const Center(
child:
CircularProgressIndicator(),
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
child: Column(
children: [

          Container(
            padding:
                const EdgeInsets.all(
              16,
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
            child: Column(
              children: [

                GestureDetector(
                  onTap:
                      pickNewsImage,
                  child:
                      Container(
                    height: 220,
                    width:
                        double.infinity,
                    decoration:
                        BoxDecoration(
                      color: AppColors
                          .primaryLight,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child:
                        uploadingImage
                            ? const Center(
                                child:
                                    CircularProgressIndicator(),
                              )
                            : imageUrl !=
                                    null
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(
                                      20,
                                    ),
                                    child:
                                        Image.network(
                                      imageUrl!,
                                      fit: BoxFit
                                          .cover,
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size:
                                            48,
                                      ),
                                      SizedBox(
                                        height:
                                            8,
                                      ),
                                      Text(
                                        'Chọn ảnh đại diện',
                                      ),
                                    ],
                                  ),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                TextField(
                  controller:
                      titleController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Tiêu đề',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                TextField(
                  controller:
                      summaryController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    labelText:
                        'Tóm tắt',
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                QuillSimpleToolbar(
                  controller:
                      quillController,
                ),

                const SizedBox(
                  height: 12,
                ),

                SizedBox(
                  height: 500,
                  child: Container(
                    decoration:
                        BoxDecoration(
                      border:
                          Border.all(
                        color:
                            Colors.grey,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child:
                        QuillEditor(
  controller: quillController,
  scrollController:
      ScrollController(),
  focusNode: FocusNode(),
  config: const QuillEditorConfig(
    padding:
        EdgeInsets.all(10),
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
  );
  }
}
