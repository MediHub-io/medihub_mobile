import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() =>
      _SplashPageState();
}

class _SplashPageState
    extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
  try {
    debugPrint('Splash Start');

    await Future.delayed(
      const Duration(seconds: 2),
    );

    final token =
        await SecureStorage.getToken();

    debugPrint(
      'TOKEN = $token',
    );

    if (!mounted) return;

    if (token != null &&
        token.isNotEmpty) {
      debugPrint('GO HOME');
      context.go('/home');
    } else {
      debugPrint('GO LOGIN');
      context.go('/login');
    }
  } catch (e, s) {
    debugPrint('SPLASH ERROR: $e');
    debugPrint('$s');

    if (mounted) {
      context.go('/login');
    }
  }
}

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/logo_full.png',
          width: 350,
        ),
      ),
    );
  }
}