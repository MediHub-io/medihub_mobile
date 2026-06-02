import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tqkashgdnndeofbzdamf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxa2FzaGdkbm5kZW9mYnpkYW1mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyNjc2MDYsImV4cCI6MjA5NTg0MzYwNn0.q1Xh1PgVGemiLFWHBJLT8eryS9VRnfm-LXJquQedICQ',
  );

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