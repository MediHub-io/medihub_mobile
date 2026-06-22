import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../data/consult_service.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  final questionController = TextEditingController();
  final scrollController = ScrollController();
  final service = ConsultService();

  final suggestions = const [
    'Lời khuyên dinh dưỡng cho người cao huyết áp?',
    'Tôi cần lưu ý gì trước khi đi xét nghiệm máu?',
    'Cách xử lý ban đầu khi bị sốt xuất huyết nhẹ?',
    'Dấu hiệu nhận biết trẻ bị thiếu canxi là gì?',
  ];

  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  @override
  void dispose() {
    questionController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> loadMessages() async {
    try {
      final data = await service.messages();
      if (!mounted) return;
      setState(() {
        messages = data.isEmpty
            ? [
                {
                  'role': 'assistant',
                  'content':
                      'Xin chào quý khách. Tôi là trợ lý AI sức khỏe của MediHub. Tôi có thể hỗ trợ tư vấn triệu chứng, giải thích kết quả xét nghiệm và cung cấp thông tin sức khỏe tham khảo.',
                },
              ]
            : data;
        loading = false;
      });
      scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        messages = [
          {
            'role': 'assistant',
            'content':
                'Hiện chưa tải được lịch sử tư vấn. Bạn vẫn có thể gửi câu hỏi, hệ thống sẽ thử kết nối lại.',
          },
        ];
        loading = false;
      });
    }
  }

  Future<void> askQuestion(String question) async {
    final content = question.trim();
    if (content.isEmpty || isTyping) return;

    setState(() {
      messages.add({'role': 'user', 'content': content});
      isTyping = true;
    });
    questionController.clear();
    scrollToBottom();

    try {
      final result = await service.send(content);
      final replies = result['messages'];
      final assistantMessage = result['assistantMessage'];
      if (!mounted) return;
      setState(() {
        if (replies is List && replies.isNotEmpty) {
          messages = replies
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } else if (assistantMessage is Map) {
          messages.add(Map<String, dynamic>.from(assistantMessage));
        } else {
          messages.add({
            'role': 'assistant',
            'content': result['reply']?.toString() ??
                'Tôi đã nhận câu hỏi của bạn nhưng chưa có phản hồi phù hợp.',
          });
        }
        isTyping = false;
      });
      scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        messages.add({
          'role': 'assistant',
          'content':
              'Gemini đang không phản hồi được. Vui lòng kiểm tra GEMINI_MODEL/GEMINI_API_KEY hoặc thử lại sau.',
        });
        isTyping = false;
      });
      scrollToBottom();
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget buildMessage(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg['content']?.toString() ?? '',
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, color: AppColors.primary, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
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
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý sức khỏe thông minh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text('Tư vấn triệu chứng', style: TextStyle(color: Colors.white)),
                Text('Giải thích xét nghiệm', style: TextStyle(color: Colors.white)),
                Text('Hướng dẫn chăm sóc', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSuggestions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gợi ý câu hỏi thường gặp',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.5,
            children: suggestions.map((suggestion) {
              var isHover = false;
              return StatefulBuilder(
                builder: (context, setHoverState) {
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setHoverState(() => isHover = true),
                    onExit: (_) => setHoverState(() => isHover = false),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => askQuestion(suggestion),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isHover
                              ? const Color(0xFFE8F5E9)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isHover
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: isHover ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            suggestion,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: isHover
                                  ? AppColors.primary
                                  : Colors.black87,
                              fontWeight:
                                  isHover ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: questionController,
              textInputAction: TextInputAction.send,
              onSubmitted: askQuestion,
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed:
                  isTyping ? null : () => askQuestion(questionController.text),
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 2),
      body: SafeArea(
        child: Column(
          children: [
            buildHeader(),
            buildSuggestions(),
            const SizedBox(height: 8),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isTyping && index == messages.length) {
                          return buildMessage({
                            'role': 'assistant',
                            'content': 'AI đang trả lời...',
                          });
                        }
                        return buildMessage(messages[index]);
                      },
                    ),
            ),
            buildInput(),
          ],
        ),
      ),
    );
  }
}
