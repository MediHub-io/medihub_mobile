import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/widgets/main_bottom_navigation.dart';
import '../../profile/presentation/widgets/profile_ui.dart';
import '../data/utility_service.dart';

class ImagingResultsPage extends StatefulWidget {
  const ImagingResultsPage({super.key});

  @override
  State<ImagingResultsPage> createState() => _ImagingResultsPageState();
}

class _ImagingResultsPageState extends State<ImagingResultsPage> {
  final service = UtilityService();
  List<dynamic> results = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await service.getImagingResults();
    if (!mounted) return;
    setState(() {
      results = data;
      loading = false;
    });
  }

  Widget card(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      item['technique'] ?? '',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormatter.displayDate(item['performedAt']),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item['imageUrl'] ?? '',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 220,
                  color: AppColors.primaryLight,
                  alignment: Alignment.center,
                  child: const Text('Hình ảnh chẩn đoán'),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Kết quả chuyên môn:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '“${item['conclusion'] ?? ''}”',
            style: const TextStyle(fontStyle: FontStyle.italic, height: 1.4),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'BS Chẩn đoán: ${item['doctorName'] ?? ''}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Text(
                item['statusLabel'] ?? '',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 0),
      body: Column(
        children: [
          const ProfileHeader(title: 'CĐ hình ảnh'),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      const Text(
                        'Lưu trữ và theo dõi phim chụp kỹ thuật số kèm nhận định chuyên môn từ bác sĩ.',
                        style: TextStyle(height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      if (results.isEmpty)
                        const _EmptyResultMessage(
                          message: 'Chưa có kết quả CĐHA đã duyệt.',
                        )
                      else
                        ...results.map(
                          (item) => card(Map<String, dynamic>.from(item)),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResultMessage extends StatelessWidget {
  const _EmptyResultMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
