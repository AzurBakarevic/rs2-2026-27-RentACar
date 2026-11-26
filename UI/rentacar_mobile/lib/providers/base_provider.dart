import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/search_result.dart';
import '../utils/api_client_exception.dart';
import 'auth_provider.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5001/');

  static final String baseUrl = _apiBaseUrl.endsWith('/') ? _apiBaseUrl : '$_apiBaseUrl/';

  static const Duration requestTimeout = Duration(seconds: 30);

  final String endpoint;

  BaseProvider(this.endpoint);

  Future<SearchResult<T>> get({Map<String, dynamic>? filter}) async {
    final uri = buildUri(endpoint, filter);
    final response = await send(() => http.get(uri, headers: createHeaders()));

    final data = jsonDecode(response.body);
    final result = SearchResult<T>();
    result.totalCount = data['totalCount'];
    result.items = List<T>.from(data['items'].map((e) => fromJson(e)));
    return result;
  }

  Future<bool> hasAny() async {
    final result = await get(filter: {'pageSize': 1});
    return result.items?.isNotEmpty ?? false;
  }

  Future<T> getById(int id) async {
    final uri = buildUri('$endpoint/$id');
    final response = await send(() => http.get(uri, headers: createHeaders()));
    return fromJson(jsonDecode(response.body));
  }

  Future<T> insert(Map<String, dynamic> request) async {
    final uri = buildUri(endpoint);
    final response = await send(() => http.post(uri, headers: createHeaders(), body: jsonEncode(request)));
    return fromJson(jsonDecode(response.body));
  }

  Future<T> update(int id, Map<String, dynamic> request) async {
    final uri = buildUri('$endpoint/$id');
    final response = await send(() => http.put(uri, headers: createHeaders(), body: jsonEncode(request)));
    return fromJson(jsonDecode(response.body));
  }

  Future<void> remove(int id) async {
    final uri = buildUri('$endpoint/$id');
    await send(() => http.delete(uri, headers: createHeaders()));
  }

  T fromJson(dynamic data);

  static Uri buildUri(String path, [Map<String, dynamic>? filter]) {
    final uri = Uri.parse('$baseUrl$path');
    if (filter == null || filter.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: getQueryParameters(filter));
  }

  static Map<String, String> getQueryParameters(Map<String, dynamic> filter) {
    final parameters = <String, String>{};
    filter.forEach((key, value) {
      if (value == null || (value is String && value.trim().isEmpty)) {
        return;
      }
      parameters[key] = value is DateTime ? value.toUtc().toIso8601String() : value.toString();
    });
    return parameters;
  }

  static Map<String, String> createHeaders() {
    final headers = {'Content-Type': 'application/json'};
    final accessToken = AuthProvider.accessToken;
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  static Future<http.Response> send(
    Future<http.Response> Function() request, {
    bool handleUnauthorized = true,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(requestTimeout);
    } on TimeoutException {
      throw ApiClientException('Server ne odgovara. Pokušajte ponovo.');
    } on SocketException {
      throw ApiClientException('Server nije dostupan. Provjerite da li je API pokrenut.');
    } on http.ClientException {
      throw ApiClientException('Server nije dostupan. Provjerite da li je API pokrenut.');
    }

    validateResponse(response, handleUnauthorized: handleUnauthorized);
    return response;
  }

  static void validateResponse(http.Response response, {bool handleUnauthorized = true}) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      return;
    }

    if (status == 401 && handleUnauthorized) {
      final error = ApiErrorParser.fromResponse(status, response.body, 'Sesija je istekla. Prijavite se ponovo.');
      AuthProvider.handleUnauthorized(error.message);
      throw UnauthorizedException(error.message);
    }

    final fallbackMessage = switch (status) {
      403 => 'Nemate pravo na ovu akciju.',
      404 => 'Traženi zapis nije pronađen.',
      >= 500 => 'Došlo je do greške na serveru. Pokušajte ponovo.',
      _ => 'Zahtjev nije moguće obraditi.',
    };
    throw ApiErrorParser.fromResponse(status, response.body, fallbackMessage);
  }
}
