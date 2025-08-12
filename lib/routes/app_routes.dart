import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpt_final_project_mobile/admin/pages/admin_home.dart';
import 'package:fpt_final_project_mobile/admin/pages/login_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/table_form_page.dart';
import 'package:fpt_final_project_mobile/admin/pages/table_list_page.dart';
import 'package:fpt_final_project_mobile/admin/services/table_service.dart';
import 'package:http/http.dart' as http;

const kBaseUrl = 'http://10.0.2.2:8080'; // đổi URL cho đúng backend
final storage = const FlutterSecureStorage();

final tableService = TableService(
  baseUrl: kBaseUrl,
  getToken: () => storage.read(key: 'token'),
  client: http.Client(),
);

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const LoginPage(),
  '/admin': (context) => const AdminHome(),

  '/admin/tables': (context) => TableListPage(service: tableService),
  '/admin/tables/create': (context) => TableFormPage(service: tableService),
};
