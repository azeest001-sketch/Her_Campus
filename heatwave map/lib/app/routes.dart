import 'package:flutter/material.dart';
import 'package:safe_campus/features/admin/admin_placeholder_page.dart';
import 'package:safe_campus/features/auth/mode_select_page.dart';
import 'package:safe_campus/features/auth/student_login_page.dart';
import 'package:safe_campus/features/heatwave/heatwave_screen.dart';
import 'package:safe_campus/features/home/student_home_page.dart';

class AppRoutes {
  static const modeSelect = '/';
  static const studentLogin = '/student-login';
  static const studentHome = '/student-home';
  static const heatwave = '/heatwave';
  static const admin = '/admin';

  static Map<String, WidgetBuilder> get routes => {
        modeSelect: (_) => const ModeSelectPage(),
        studentLogin: (_) => const StudentLoginPage(),
        studentHome: (_) => const StudentHomePage(),
        heatwave: (_) => const HeatwaveScreen(),
        admin: (_) => const AdminPlaceholderPage(),
      };
}
