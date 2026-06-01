import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MediHubApp());
}

class MediHubApp extends StatelessWidget {
  const MediHubApp({super.key});

  @override
  Widget build(BuildContext context) {
   return MaterialApp.router(
    title: 'MediHub',
    debugShowCheckedModeBanner: false,

    theme: AppTheme.lightTheme,

    routerConfig: appRouter,
  );
  }
}