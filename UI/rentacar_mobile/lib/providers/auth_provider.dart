import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/api_client_exception.dart';
import 'base_provider.dart';

class AuthProvider with ChangeNotifier {
  static const String customerRole = 'Korisnik';

  static String? _accessToken;
  static int? _userId;

  static String? get accessToken => _accessToken;
  static int? get userId => _userId;

  static void Function(String message)? onSessionExpired;

  bool get isAuthenticated => _accessToken != null;

  Future<void> login(String username, String password) async {
    final response = await _postAnonymous('Access/Login', {'username': username, 'password': password});

    final data = jsonDecode(response.body);
    if (data['role'] != customerRole) {
      throw ApiClientException('Mobilna aplikacija je namijenjena korisnicima. Administratori koriste desktop aplikaciju.');
    }

    _accessToken = data['accessToken'];
    _userId = data['userId'];
    notifyListeners();
  }

  Future<void> register(Map<String, dynamic> request) => _postAnonymous('Access/Register', request);

  Future<void> requestPasswordReset(String email) => _postAnonymous('Access/ForgotPassword', {'email': email});

  Future<void> resetPassword(Map<String, dynamic> request) => _postAnonymous('Access/ResetPassword', request);

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
      endSession();
    }
  }

  void endSession() {
    _clearSession();
    notifyListeners();
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
  }

  static Future<http.Response> _postAnonymous(String path, Map<String, dynamic> body) {
    return BaseProvider.send(
      () => http.post(BaseProvider.buildUri(path), headers: BaseProvider.createHeaders(), body: jsonEncode(body)),
      handleUnauthorized: false,
    );
  }
}
