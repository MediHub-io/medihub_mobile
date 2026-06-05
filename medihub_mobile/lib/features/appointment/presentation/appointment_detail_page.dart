import 'package:flutter/material.dart';
import '../data/appointment_service.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/medihub_page.dart';
import '../../../shared/widgets/medihub_card.dart';

String getStatusText(
  String status,
) {
  switch (status) {

    case 'REQUESTED':
      return 'Đang chờ xác nhận';

    case 'PROPOSED':
      return 'BV đề xuất lịch';

    case 'CONFIRMED':
      return 'Đã xác nhận';

    case 'COMPLETED':
      return 'Đã khám';

    case 'CANCELLED':
      return 'Đã hủy';

    default:
      return status;
  }
}

Color getStatusColor(
  String status,
) {
  switch (status) {
    case 'REQUESTED':
      return AppColors.warning;

    case 'PROPOSED':
      return AppColors.secondary;

    case 'CONFIRMED':
      return AppColors.success;

    case 'COMPLETED':
      return AppColors.textSecondary;

    case 'CANCELLED':
      return AppColors.error;

    default:
      return AppColors.textSecondary;
  }
}



class AppointmentDetailPage
    extends StatefulWidget {

  final Map<String, dynamic>
      appointment;

  const AppointmentDetailPage({
    super.key,
    required this.appointment,
  });


@override
State<AppointmentDetailPage>
    createState() =>
        _AppointmentDetailPageState();
}

class _AppointmentDetailPageState
    extends State<AppointmentDetailPage> {

final service =
    AppointmentService();

bool loading = false;
bool detailLoading = true;
Map<String, dynamic>? detail;

@override
void initState() {
  super.initState();

  loadDetail();
}

Future<void> loadDetail() async {
  final data =
      await service.getAppointmentDetail(
    widget.appointment['id'],
  );

  if (!mounted) return;

  setState(() {
    detail = data;
    detailLoading = false;
  });
}

Future<void> confirm() async {

  setState(() {
    loading = true;
  });

  await service.confirmAppointment(
    widget.appointment['id'],
  );

  if (!mounted) return;

  context.pop(true);
}

Future<void> cancel() async {

  setState(() {
    loading = true;
  });

  await service.cancelAppointment(
    widget.appointment['id'],
  );

  if (!mounted) return;

  context.pop(true);
}


  @override
  Widget build(
    BuildContext context,
  ) {


        if (detailLoading) {
        return const Scaffold(
            body: Center(
            child:
                CircularProgressIndicator(),
            ),
        );
        }

        final appointment = detail!;


    return MediHubPage(
        title: 'Chi tiết lịch khám',
        child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            MediHubCard(
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: getStatusColor(
              appointment['status'] ?? '',
            ).withOpacity(0.15),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Text(
            getStatusText(
              appointment['status'] ?? '',
            ),
            style: TextStyle(
              color: getStatusColor(
                appointment['status'] ?? '',
              ),
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          appointment['doctorName'] ?? 'Chưa sắp xếp lịch',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          appointment['department'] ?? '',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              const Text(
                'Ngày khám',
                style: TextStyle(
                  color:
                      AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                appointment['appointmentDate'] != null
                    ? appointment['appointmentDate']
                        .toString()
                        .substring(0, 10)
                    : '--',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [

            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Ngày mong muốn',
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appointment['requestedDate']
                              ?.toString()
                              .substring(0, 10) ??
                          '--',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Trạng thái',
                      style: TextStyle(
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                    getStatusText(
                        appointment['status'] ?? '',
                    ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
 ),
),

const SizedBox(
  height: 16,
),

MediHubCard(
                child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                    const Text(
                        'Ghi chú',
                        style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        ),
                    ),

                    const SizedBox(
                        height: 8,
                    ),

                    Text(
                        appointment['note'] ??
                            '',
                    ),


                    if (
                        appointment['medicalRecord'] != null
                        )
                        Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius:
                                    BorderRadius.circular(18),
                            ),
                        child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                                const Text(
                                'Kết quả khám',
                                style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                ),
                                ),

                                const SizedBox(
                                height: 12,
                                ),

                                Text(
                                'Chẩn đoán: '
                                '${appointment['medicalRecord']['diagnosis'] ?? ''}',
                                ),

                                const SizedBox(
                                height: 8,
                                ),

                                Text(
                                'Kết luận: '
                                '${appointment['medicalRecord']['conclusion'] ?? ''}',
                                ),

                                const SizedBox(
                                height: 8,
                                ),

                                Text(
                                'Ghi chú: '
                                '${appointment['medicalRecord']['note'] ?? ''}',
                                ),
                            ],
                            ),
                        ),
                        ),
        


                    ],
                  ),
                ),
              ),

if (
  appointment['status'] ==
  'PROPOSED'
)
...[
  const SizedBox(
    height: 24,
  ),

  Row(
    children: [

      Expanded(
        child: ElevatedButton(
          onPressed:
              loading
                  ? null
                  : confirm,
          child: const Text(
            'Xác nhận',
          ),
        ),
      ),

      const SizedBox(
        width: 12,
      ),

      Expanded(
        child: OutlinedButton(
          onPressed:
              loading
                  ? null
                  : cancel,
          child: const Text(
            'Từ chối',
          ),
        ),
      ),
    ],
  ),
],

          ],
        ),
      ),
    );
  }
}