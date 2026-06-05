class NewsModel {
  final String id;

  final String title;

  final String summary;

  final String content;

  final String? imageUrl;

  final bool isPublished;

  NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    this.imageUrl,
    required this.isPublished,
  });

  factory NewsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return NewsModel(
      id: json['id'],
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      isPublished:
          json['isPublished'] ?? true,
    );
  }
}