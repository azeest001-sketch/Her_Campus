import 'package:flutter/material.dart';

void main() {
  runApp(const HerCampusApp());
}

/// App entry point. Teammates can grow this as screens are added.
class HerCampusApp extends StatelessWidget {
  const HerCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Her Campus',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('Her Campus'),
        ),
      ),
    );
  }
}
