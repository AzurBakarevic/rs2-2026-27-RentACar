import 'dart:convert';

class ApiClientException implements Exception {
  ApiClientException(this.message, {this.fieldErrors = const {}, this.statusCode});

  final String message;

  final Map<String, String> fieldErrors;

  final int? statusCode;

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiClientException {
  UnauthorizedException(super.message) : super(statusCode: 401);
}

class ApiErrorParser {
  ApiErrorParser._();

  static const _generalErrorKeys = {'clientError', 'serverError'};

  static ApiClientException fromResponse(int statusCode, String body, String fallbackMessage) {
    String? message;
    final fieldErrors = <String, String>{};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final root = decoded['message'];
        if (root is String && root.trim().isNotEmpty) {
          message = root.trim();
        }

        final errors = decoded['errors'];
        if (errors is Map) {
          errors.forEach((key, value) {
            final first = _firstMessage(value);
            if (first != null && !_generalErrorKeys.contains(key)) {
              fieldErrors[_toCamelCase(key.toString())] = first;
            }
          });
        }
      }
    } on FormatException catch (_) {
    }

    return ApiClientException(
      message ?? fallbackMessage,
      fieldErrors: fieldErrors,
      statusCode: statusCode,
    );
  }

  static String? _firstMessage(dynamic value) {
    if (value is List) {
      for (final item in value) {
        final text = item.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    } else if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static String _toCamelCase(String key) =>
      key.isEmpty ? key : key[0].toLowerCase() + key.substring(1);
}
