import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/api_client_exception.dart';
import 'base_provider.dart';

class AuthProvider with ChangeNotifier {
  // Naziv uloge kao u seedu na backendu (RoleNames.Administrator).
  static const String administratorRole = 'Administrator';

  static String? _accessToken;
  static String? _username;

  static String? get accessToken => _accessToken;
  static String? get username => _username;

  /// Postavlja ga main.dart: vraća aplikaciju na ekran prijave s porukom.
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
      // Token se ne čuva. Odjava na serveru bi korisnika odjavila i s mobilne aplikacije.
      throw ApiClientException('Pristup desktop aplikaciji imaju samo administratori.');
    }

    _accessToken = data['accessToken'];
    _username = data['username'];
    notifyListeners();
  }

  /// Poništava token na serveru; lokalna sesija se briše i kad server nije dostupan.
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

  /// Poziva ga BaseProvider kad API vrati 401 za prijavljenog korisnika.
  static void handleUnauthorized(String message) {
    // Kod više paralelnih zahtjeva samo prvi 401 vraća na prijavu.
    if (_accessToken == null) {
      return;
    }
    _clearSession();
    onSessionExpired?.call(message);
  }

  static void _clearSession() {
    _accessToken = null;
    _username = null;
  }
}
