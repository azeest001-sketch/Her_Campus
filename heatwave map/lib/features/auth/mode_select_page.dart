import 'package:flutter/material.dart';
import 'package:safe_campus/app/routes.dart';

class ModeSelectPage extends StatelessWidget {
  const ModeSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe Campus')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Choose mode',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Student mode is ready. Admin mode is a placeholder for teammates.',
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppRoutes.studentLogin);
              },
              child: const Text('Student mode'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.admin);
              },
              child: const Text('Admin mode'),
            ),
          ],
        ),
      ),
    );
  }
}
