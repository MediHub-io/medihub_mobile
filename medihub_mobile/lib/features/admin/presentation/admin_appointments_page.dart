import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/admin_appointment_service.dart';
import '../../../core/theme/app_colors.dart';

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({
    super.key,
  });

  @override
  State<AdminAppointmentsPage> createState() =>
      _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState
    extends State<AdminAppointmentsPage> {
  final service =
      AdminAppointmentService();

  List<dynamic> appointments = [];

  bool loading = true;

  String selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final result =
          await service.getAppointments();

      if (!mounted) return;

      setState(() {
        appointments = result;
        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  List<dynamic> get filteredAppointments {
    if (selectedStatus == 'ALL') {
      return appointments;
    }

    return appointments
        .where(
          (e) =>
              e['status'] ==
              selectedStatus,
        )
        .toList();
  }

  Color statusColor(
  String status,
) {
  switch (status) {
    case 'REQUESTED':
      return AppColors.warning;

    case 'PROPOSED':
        return AppColors.proposed;

    case 'CONFIRMED':
      return AppColors.success;

    case 'COMPLETED':
         return AppColors.completed;

    case 'CANCELLED':
      return AppColors.error;

    default:
      return AppColors.textSecondary;
  }
}

  String statusText(
    String status,
  ) {
    switch (status) {
      case 'REQUESTED':
        return 'Yêu cầu mới';

      case 'PROPOSED':
        return 'Đã đề xuất';

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

  Future<void> showProposeDialog(
    Map<String, dynamic> item,
  ) async {
    final doctorController =
        TextEditingController();

    final departmentController =
        TextEditingController();

    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Đề xuất lịch khám',
          ),
          content: StatefulBuilder(
            builder: (
              context,
              setDialogState,
            ) {
              return SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          doctorController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Bác sĩ',
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller:
                          departmentController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Khoa',
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final date =
                            await showDatePicker(
                          context:
                              context,
                          firstDate:
                              DateTime.now(),
                          lastDate:
                              DateTime(
                            2030,
                          ),
                          initialDate:
                              DateTime.now(),
                        );

                        if (date == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedDate =
                              date;
                        });
                      },
                      icon: const Icon(
                        Icons.calendar_month,
                      ),
                      label: Text(
                        selectedDate ==
                                null
                            ? 'Chọn ngày khám'
                            : selectedDate!
                                .toString()
                                .substring(
                                  0,
                                  10,
                                ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child: const Text(
                'Hủy',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate ==
                    null) {
                  return;
                }

                await service
                    .proposeAppointment(
                  id: item['id'],
                  appointmentDate:
                      selectedDate!
                          .toIso8601String(),
                  doctorName:
                      doctorController
                          .text,
                  department:
                      departmentController
                          .text,
                );

                if (!mounted) return;

                Navigator.pop(
                  context,
                );

                await loadData();
              },
              child: const Text(
                'Đề xuất',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(
  BuildContext context,
) {
  return Scaffold(
    backgroundColor:
        AppColors.background,
    appBar: AppBar(
  elevation: 0,
  centerTitle: true,
  backgroundColor:
      AppColors.primary,
  foregroundColor:
      AppColors.white,
  title: const Text(
    'Quản lý lịch khám',
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
        : Column(
            children: [

              Padding(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child: Container(
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
                  child:
                      DropdownButtonFormField<
                          String>(
                    value:
                        selectedStatus,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Lọc trạng thái',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ALL',
                        child:
                            Text('Tất cả'),
                      ),
                      DropdownMenuItem(
                        value:
                            'REQUESTED',
                        child: Text(
                          'Yêu cầu mới',
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                            'PROPOSED',
                        child: Text(
                          'Đã đề xuất',
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                            'CONFIRMED',
                        child: Text(
                          'Đã xác nhận',
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                            'COMPLETED',
                        child: Text(
                          'Đã khám',
                        ),
                      ),
                      DropdownMenuItem(
                        value:
                            'CANCELLED',
                        child: Text(
                          'Đã hủy',
                        ),
                      ),
                    ],
                    onChanged: (
                      value,
                    ) {
                      setState(() {
                        selectedStatus =
                            value!;
                      });
                    },
                  ),
                ),
              ),

              Expanded(
                child:
                    RefreshIndicator(
                  onRefresh:
                      loadData,
                  child:
                      ListView.builder(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    itemCount:
                        filteredAppointments
                            .length,
                    itemBuilder:
                        (
                      context,
                      index,
                    ) {
                      final item =
                          filteredAppointments[
                              index];

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: MouseRegion(
                          cursor:
                              SystemMouseCursors
                                  .click,
                          child: InkWell(
                            onTap:
                                () async {
                              await context.push(
                                '/admin/appointment/${item['id']}',
                              );

                              await loadData();
                            },
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
  child:

                                  ListTile(
                                leading:
                                    CircleAvatar(
                                  backgroundColor:
                                      statusColor(
                                    item[
                                        'status'],
                                  ),
                                ),
                                title:
                                    Text(
                                  item['patientName'] ??
                                      'Bệnh nhân',
                                ),
                                subtitle:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'Ngày mong muốn: ${item['requestedDate']?.toString().substring(0, 10) ?? ''}',
                                    ),
                                    Text(
                                      statusText(
                                        item['status'],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing:
                                    item['status'] ==
                                            'REQUESTED'
                                        ? ElevatedButton(
    style:
        ElevatedButton.styleFrom(
      backgroundColor:
          AppColors.primary,
      foregroundColor:
          AppColors.white,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
    ),
                                            onPressed:
                                                () {
                                              showProposeDialog(
                                                item,
                                              );
                                            },
                                            child:
                                                const Text(
                                              'Đề xuất',
                                            ),
                                          )
                                        : item['status'] ==
                                                'CONFIRMED'
                                            ? ElevatedButton(
    style:
        ElevatedButton.styleFrom(
      backgroundColor:
          AppColors.success,
      foregroundColor:
          AppColors.white,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
    ),
    onPressed:
                                                    () async {
                                                  final result =
                                                      await context.push(
                                                    '/doctor-complete/${item['id']}',
                                                  );

                                                  if (result ==
                                                      true) {
                                                    await loadData();
                                                  }
                                                },
                                                child:
                                                    const Text(
                                                  'Bắt đầu khám',
                                                ),
                                              )
                                            : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
  );
}
}