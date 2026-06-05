import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
//import '../../../shared/widgets/medihub_page.dart';
import '../../../shared/widgets/medihub_card.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor:
      AppColors.background,

  appBar: AppBar(
    elevation: 0,
    centerTitle: true,
    automaticallyImplyLeading:
        false,
    backgroundColor:
        AppColors.primary,
    foregroundColor:
        AppColors.white,
    title: const Text(
      'Quản trị hệ thống',
      style: TextStyle(
        fontWeight:
            FontWeight.bold,
      ),
    ),
  ),

  body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

         MediHubCard(
            child: Material(
                color: Colors.transparent,
                child: ListTile(
              leading: Icon(
                Icons.article,
                color: AppColors.secondary,
                ),
              title: const Text(
                'Quản lý tin tức',
              ),
              trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                            ),
              onTap: () {
                context.push(
                  '/admin/news',
                );
              },
            ),
            ),
          ),

          MediHubCard(
            child: Material(
                color: Colors.transparent,
                child: ListTile(
              leading: Icon(
                Icons.calendar_month,
                color: AppColors.primary,
                ),
              title: const Text(
                'Quản lý lịch khám',
              ),
               trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                            ),
              onTap: () {
                context.push(
                    '/admin/appointments',
                );
            },
            ),
            ),
          ),

          MediHubCard(
            child: Material(
                color: Colors.transparent,
                child: ListTile(
              leading: Icon(
                Icons.people,
                color: AppColors.success,
                ),
              title: const Text(
                'Quản lý bệnh nhân',
              ),
               trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                            ),
               onTap: () {
                context.push(
                    '/admin/patients',
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