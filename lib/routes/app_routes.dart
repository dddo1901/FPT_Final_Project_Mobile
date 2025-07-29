import 'package:flutter/material.dart';
import 'package:fpt_final_project_mobile/admin/pages/admin_home.dart';
import 'package:fpt_final_project_mobile/admin/pages/login_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/verify_otp_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const LoginPage(),
  '/admin': (context) => const AdminHome(),
  '/verify': (context) => const VerifyOtpPage(),
};
