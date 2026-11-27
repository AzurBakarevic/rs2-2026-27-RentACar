import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_notification.dart';
import '../utils/api_client_exception.dart';
import 'base_provider.dart';

class NotificationProvider extends BaseProvider<AppNotification> {
  NotificationProvider() : super('Notifications');

  static const Duration pollInterval = Duration(seconds: 20);

  Timer? _timer;
  int _requestId = 0;
  int _unreadCount = 0;
  int? _latestUnreadId;

  int get unreadCount => _unreadCount;
  int? get latestUnreadId => _latestUnreadId;

  @override
  AppNotification fromJson(data) {
    return AppNotification.fromJson(data);
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => refresh());
    refresh();
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _requestId++;
  }

  void clear() {
    stopPolling();
    _unreadCount = 0;
    _latestUnreadId = null;
  }

  Future<void> refresh() async {
    final requestId = ++_requestId;
    try {
      final result = await get(filter: {'isRead': false, 'pageSize': 1, 'includeTotalCount': true});
      if (requestId == _requestId) {
        _apply(result.totalCount ?? 0, result.items?.firstOrNull?.id);
      }
    } on UnauthorizedException catch (_) {
      stopPolling();
    } on ApiClientException catch (e) {
      debugPrint('Provjera notifikacija nije uspjela: ${e.message}');
    } catch (e) {
      debugPrint('Provjera notifikacija nije uspjela: $e');
    }
  }

  Future<void> markAsRead(int id) async {
    await _put('$endpoint/$id/Read');
    await refresh();
  }

  Future<void> markAllAsRead() async {
    await _put('$endpoint/ReadAll');
    _requestId++;
    _apply(0, null);
  }

  void _apply(int unreadCount, int? latestUnreadId) {
    if (unreadCount == _unreadCount && latestUnreadId == _latestUnreadId) {
      return;
    }
    _unreadCount = unreadCount;
    _latestUnreadId = latestUnreadId;
    notifyListeners();
  }

  Future<http.Response> _put(String path) {
    final uri = BaseProvider.buildUri(path);
    return BaseProvider.send(() => http.put(uri, headers: BaseProvider.createHeaders()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
