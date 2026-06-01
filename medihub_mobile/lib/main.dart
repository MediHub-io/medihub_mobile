import 'package:flutter/material.dart';
import 'routes/app_router.dart';

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
      routerConfig: appRouter,
    );
  }
}