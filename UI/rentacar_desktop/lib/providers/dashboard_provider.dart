import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/dashboard.dart';
import 'base_provider.dart';

class DashboardProvider with ChangeNotifier {
  Future<Dashboard> get() async {
    final response = await BaseProvider.send(
      () => http.get(BaseProvider.buildUri('Dashboard'), headers: BaseProvider.createHeaders()),
    );
    return Dashboard.fromJson(jsonDecode(response.body));
  }
}
