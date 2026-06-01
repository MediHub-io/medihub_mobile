import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(
    BuildContext context,
  ) async {
    await SecureStorage.clear();

    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('MediHub Home'),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.logout),
            onPressed:
                () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Đăng nhập thành công',
        ),
      ),
    );
  }
}