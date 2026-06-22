import 'package:flutter/material.dart';
import '../data/doctor_service.dart';
import '../../../core/theme/app_colors.dart';

class DoctorCompletePage extends StatefulWidget {
  final String appointmentId;

  const DoctorCompletePage({
    super.key,
    required this.appointmentId,
  });

  @override
  State<DoctorCompletePage> createState() =>
      _DoctorCompletePageState();
}

class _DoctorCompletePageState
    extends State<DoctorCompletePage> {
  final diagnosisController =
      TextEditingController();

  final conclusionController =
      TextEditingController();

  final noteController =
      TextEditingController();

  bool loading = false;
  final service = DoctorService();

  Future<void> submit() async {

    if (
    diagnosisController.text
        .trim()
        .isEmpty
) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(
    const SnackBar(
      content: Text(
        'Vui lòng nhập chẩn đoán',
      ),
    ),
  );
  return;
}

if (
    conclusionController.text
        .trim()
        .isEmpty
) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(
    const SnackBar(
      content: Text(
        'Vui lòng nhập kết luận',
      ),
    ),
  );
  return;
}

if (
    noteController.text
        .trim()
        .isEmpty
) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(
    const SnackBar(
      content: Text(
        'Vui lòng nhập hướng điều trị',
      ),
    ),
  );
  return;
}

  setState(() {
    loading = true;
  });

  try {

    await service.completeAppointment(
      appointmentId: widget.appointmentId,
      diagnosis:
          diagnosisController.text,
      conclusion:
          conclusionController.text,
      note:
          noteController.text,
    );

    if (!mounted) return;

    Navigator.pop(
      context,
      true,
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
  body: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary,
          AppColors.primaryLight,
          AppColors.background,
        ],
      ),
    ),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Container(
  width: double.infinity,
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(24),
    boxShadow: const [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  ),
  child: Row(
    children: [

      Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.white,
          ),
        ),
      ),

      const Expanded(
        child: Text(
          'Kết quả khám',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      const SizedBox(
        width: 48,
      ),
    ],
  ),
),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: Column(
                children: [

                  TextField(
                    controller:
                        diagnosisController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Chẩn đoán',
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  TextField(
                    controller:
                        conclusionController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Kết luận',
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  TextField(
                    controller:
                        noteController,
                    maxLines: 5,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Hướng điều trị',
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        ElevatedButton(
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            AppColors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),
                      onPressed:
                          loading
                              ? null
                              : submit,
                      child:
                          const Text(
                        'Hoàn thành khám',
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
