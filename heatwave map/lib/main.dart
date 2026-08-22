import 'package:flutter/material.dart';
import 'package:safe_campus/app/app.dart';
import 'package:safe_campus/app/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.init();
  runApp(const SafeCampusApp());
}
