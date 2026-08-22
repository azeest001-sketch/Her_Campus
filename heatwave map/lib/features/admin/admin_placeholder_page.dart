import 'package:flutter/material.dart';

class AdminPlaceholderPage extends StatelessWidget {
  const AdminPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin mode')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Admin mode — teammate placeholder.\n\n'
          'Replace this page with admin features when merging.',
        ),
      ),
    );
  }
}
