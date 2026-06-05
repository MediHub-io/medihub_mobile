import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';

class ConsultPage extends StatefulWidget {
const ConsultPage({super.key});

@override
State<ConsultPage> createState() =>
_ConsultPageState();
}

class _ConsultPageState
extends State<ConsultPage> {

final TextEditingController
questionController =
TextEditingController();

final List<Map<String, dynamic>>
messages = [


{
  'role': 'assistant',
  'content':
      'Xin chào quý khách. Tôi là trợ lý AI sức khỏe của MediHub. Tôi có thể hỗ trợ tư vấn triệu chứng, giải thích kết quả xét nghiệm và cung cấp thông tin sức khỏe tham khảo.',
},


];

bool isTyping = false;

final suggestions = [


'Lời khuyên dinh dưỡng cho ngời cao huyết áp',

'Tôi cần lưu ý gì tróc khi đi xét nghiệm máu?',

'Cách xử lý ban đầu khi bị sốt xuất huyết nhẹ?',

'Dấu hiệu nhận biết trẻ bị thiếu canxi là gì?',

];

Future<void> askQuestion(
String question,
) async {


if (question.trim().isEmpty) {
  return;
}

setState(() {

  messages.add({
    'role': 'user',
    'content': question,
  });

  isTyping = true;
});

questionController.clear();

await Future.delayed(
  const Duration(
    seconds: 1,
  ),
);

if (!mounted) return;

setState(() {

  messages.add({
    'role': 'assistant',
    'content':
        'Đây là câu trả lời mẫu từ AI MediHub. Sau này sẽ kết nối OpenAI, Gemini hoặc Grok để trả lời thực tế.',
  });

  isTyping = false;
});


}

Widget buildMessage(
Map<String, dynamic> msg,
) {


final isUser =
    msg['role'] == 'user';

return Padding(
  padding:
      const EdgeInsets.only(
    top: 6,
    bottom: 6,
  ),
  child: Row(
    mainAxisAlignment:
        isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
  crossAxisAlignment:
      CrossAxisAlignment.start,
  children: [

    if (!isUser) ...[

      const CircleAvatar(
        radius: 18,
        backgroundColor:
            AppColors.primary,
        child: Icon(
          Icons.smart_toy,
          color: Colors.white,
          size: 18,
        ),
      ),

      const SizedBox(
        width: 8,
      ),
    ],

    Container(
      padding:
          const EdgeInsets.all(14),
      constraints:
          const BoxConstraints(
        maxWidth: 320,
      ),
      decoration:
          BoxDecoration(
        color: isUser
            ? AppColors.primary
            : Colors.white,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        boxShadow: const [
          BoxShadow(
            color:
                AppColors.shadow,
            blurRadius: 8,
            offset:
                Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        msg['content'],
        style: TextStyle(
          color:
              isUser
                  ? Colors.white
                  : AppColors
                      .textPrimary,
        ),
      ),
    ),

    if (isUser) ...[

      const SizedBox(
        width: 8,
      ),

      const CircleAvatar(
        radius: 18,
        backgroundColor:
            AppColors.primaryLight,
        child: Icon(
          Icons.person,
          color:
              AppColors.primary,
          size: 18,
        ),
      ),
    ],
 ],
  ),
);


}

@override
Widget build(
BuildContext context,
) {
return Scaffold(


  backgroundColor:
      const Color(
    0xFFF7F9FC,
  ),

  bottomNavigationBar:
      const MainBottomNavigation(
    currentIndex: 2,
  ),

  body: SafeArea(
    child: Column(
      children: [

        Container(
          margin:
              const EdgeInsets.all(
            16,
          ),
          padding:
              const EdgeInsets.all(
            18,
          ),
          decoration:
              BoxDecoration(
            color:
                AppColors.primary,
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
                    Offset(
                  0,
                  8,
                ),
              ),
            ],
          ),
          child: Row(
            children: [

              Container(
                width: 56,
                height: 56,
                decoration:
                    const BoxDecoration(
                  color:
                      Colors.white,
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons.smart_toy,
                  color:
                      AppColors.primary,
                  size: 30,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              const Expanded(
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                        Text(
                            'Trợ lý sức khỏe thông minh',
                            style: TextStyle(
                            color:
                                Colors.white,
                                 fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                            ),
                        ),

                        SizedBox(height: 6),

                        Text(
                            '✓ Tư vấn triệu chứng',
                            style: TextStyle(
                            color:
                                Colors.white,
                            ),
                        ),

                        Text(
                            '✓ Giải thích xét nghiệm',
                            style: TextStyle(
                            color:
                                Colors.white,
                            ),
                        ),

                        Text(
                            '✓ Hướng dẫn chăm sóc',
                            style: TextStyle(
                            color:
                                Colors.white,
                            ),
                        ),
                        ],
                    ),
                    )
            ],
          ),
        ),

//Gợi ý câu hỏi
        Container(
  margin: const EdgeInsets.symmetric(
    horizontal: 16,
  ),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius:
        BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [

      const Text(
        'GỢI Ý CÂU HỎI THƯỜNG GẶP',
        style: TextStyle(
          fontWeight:
              FontWeight.bold,
          fontSize: 16,
        ),
      ),

      const SizedBox(
        height: 12,
      ),

      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 2.2,
        children:
            suggestions.map((e) {

            return InkWell(
            onTap: () {
                askQuestion(e);
            },
            child: Container(
                padding:
                    const EdgeInsets.all(3),
                decoration:
                    BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                    12,
                ),
                border: Border.all(
                    color:
                        Colors.grey.shade300,
                ),
                ),
                child: Center(
                child: Text(
                    e,
                    textAlign:
                        TextAlign.center,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                ),
                ),
            ),
            );
        }).toList(),
        ),
    ],
  ),
),
//Hết gợi ý câu hỏi

        const SizedBox(
          height: 8,
        ),

        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.all(
              16,
            ),
            itemCount:
                messages.length +
                (isTyping ? 1 : 0),
            itemBuilder:
                (context, index) {

              if (isTyping &&
                  index ==
                      messages.length) {

                return Align(
                  alignment:
                      Alignment
                          .centerLeft,
                  child:
                      Container(
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child:
                        const Text(
                      'AI đang trả lời...',
                    ),
                  ),
                );
              }

              return buildMessage(
                messages[index],
              );
            },
          ),
        ),

        Container(
          padding:
              const EdgeInsets.all(
            12,
          ),
          decoration:
              const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: [

              Expanded(
                child: TextField(
                  controller:
                      questionController,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Nhập câu hỏi...',
                    filled: true,
                    fillColor:
                        Colors.grey.shade100,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Container(
                decoration:
                    const BoxDecoration(
                  color:
                      AppColors.primary,
                  shape:
                      BoxShape.circle,
                ),
                child:
                    IconButton(
                  onPressed: () {
                    askQuestion(
                      questionController
                          .text,
                    );
                  },
                  icon: const Icon(
                    Icons.send_rounded,
                    color:
                        Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);


}
}
