import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/api_client_exception.dart';
import 'base_provider.dart';

class AuthProvider with ChangeNotifier {
  static const String administratorRole = 'Administrator';

  static String? _accessToken;
  static int? _userId;
  static String? _username;

  static String? get accessToken => _accessToken;
  static int? get userId => _userId;
  static String? get username => _username;

  static void Function(String message)? onSessionExpired;

  bool get isAuthenticated => _accessToken != null;

  Future<void> login(String username, String password) async {
    final response = await BaseProvider.send(
      () => http.post(
        BaseProvider.buildUri('Access/Login'),
        headers: BaseProvider.createHeaders(),
        body: jsonEncode({'username': username, 'password': password}),
      ),
      handleUnauthorized: false,
    );

    final data = jsonDecode(response.body);
    if (data['role'] != administratorRole) {
      throw ApiClientException('Pristup desktop aplikaciji imaju samo administratori.');
    }

    _accessToken = data['accessToken'];
    _userId = data['userId'];
    _username = data['username'];
    notifyListeners();
  }

  Future<void> logout() async {
    if (_accessToken == null) {
      return;
    }

    try {
      await BaseProvider.send(
        () => http.post(BaseProvider.buildUri('Access/Logout'), headers: BaseProvider.createHeaders()),
        handleUnauthorized: false,
      );
    } on ApiClientException catch (e) {
      debugPrint('Odjava na serveru nije uspjela: $e');
    } finally {
      _clearSession();
      notifyListeners();
    }
  }

  static void handleUnauthorized(String message) {
    if (_accessToken == null) {
      return;
    }
    _clearSession();
    onSessionExpired?.call(message);
  }

  static void _clearSession() {
    _accessToken = null;
    _userId = null;
    _username = null;
  }
}
