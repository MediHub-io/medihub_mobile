import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import 'widgets/profile_ui.dart';

class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  static const content = '''
Chính sách Riêng tư ("Chính sách Riêng tư") được soạn ra để cho bạn biết cách chúng tôi thu thập, sử dụng thông tin và chia sẻ những thông tin đó qua Dịch Vụ.

BẰNG CÁCH TẢI XUỐNG, TRUY CẬP HOẶC SỬ DỤNG ỨNG DỤNG HOẶC DỊCH VỤ VÀ/HOẶC ĐĂNG KÝ VỚI CHÚNG TÔI HOẶC CUNG CẤP THÔNG TIN CHO CHÚNG TÔI THÔNG QUA ỨNG DỤNG, BẠN CHẤP NHẬN CÁC HOẠT ĐỘNG VÀ CHÍNH SÁCH ĐƯỢC TRÌNH BÀY TRONG CHÍNH SÁCH RIÊNG TƯ NÀY.

1. THU THẬP THÔNG TIN

Thông Tin Bạn Cung Cấp Cho Chúng Tôi

Chúng tôi thu thập những thông tin được bạn cung cấp trực tiếp, chẳng hạn như khi bạn tạo hoặc sửa đổi tài khoản, yêu cầu dịch vụ y tế, liên hệ với bộ phận hỗ trợ khách hàng hoặc liên lạc với chúng tôi. Thông tin này có thể bao gồm nhưng không giới hạn ở: tên, email, số điện thoại, địa chỉ, ảnh đại diện và các thông tin khác mà bạn chọn cung cấp.

Thông Tin Chúng Tôi Thu Thập Thông Qua Việc Sử Dụng Dịch Vụ

Khi bạn sử dụng Dịch Vụ của chúng tôi, chúng tôi thu thập thông tin về giao dịch, lịch hẹn, yêu cầu dịch vụ, ngày và giờ dịch vụ được cung cấp, số tiền phải trả và các chi tiết giao dịch khác có liên quan.

2. SỬ DỤNG THÔNG TIN

Thông tin được dùng để cung cấp dịch vụ y tế, xác thực tài khoản, hỗ trợ khách hàng, cải thiện chất lượng dịch vụ và tuân thủ các yêu cầu pháp lý.

3. BẢO MẬT

Chúng tôi áp dụng các biện pháp kỹ thuật và tổ chức phù hợp để bảo vệ thông tin cá nhân khỏi truy cập, sử dụng hoặc tiết lộ trái phép.
''';

  List<Map<String, dynamic>> _buildJustifiedDelta(
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

  QuillController _buildController() {
    return QuillController(
      document: Document.fromJson(
        _buildJustifiedDelta(content),
      ),
      selection: const TextSelection.collapsed(
        offset: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _buildController();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(
        currentIndex: 3,
      ),
      body: Column(
        children: [
          const ProfileHeader(
            title: 'Chính sách dịch vụ',
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                18,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IgnorePointer(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.5,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                    child: QuillEditor.basic(
                      controller: controller,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
