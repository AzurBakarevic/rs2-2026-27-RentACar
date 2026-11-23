import 'package:flutter/foundation.dart';

import '../providers/base_provider.dart';
import 'api_client_exception.dart';

class PagedListController<T> extends ChangeNotifier {
  PagedListController(this._provider, {this.pageSize = 10});

  final BaseProvider<T> _provider;
  final int pageSize;

  Map<String, dynamic> _filter = {};
  List<T> items = [];
  int page = 1;
  int totalCount = 0;
  bool isLoading = false;
  String? error;

  int _requestId = 0;
  bool _disposed = false;

  int get pageCount => totalCount == 0 ? 1 : (totalCount + pageSize - 1) ~/ pageSize;

  Future<void> load() async {
    final requestId = ++_requestId;
    isLoading = true;
    error = null;
    _notify();

    try {
      final result = await _provider.get(filter: {
        ..._filter,
        'page': page,
        'pageSize': pageSize,
        'includeTotalCount': true,
      });
      if (requestId != _requestId || _disposed) {
        return;
      }

      totalCount = result.totalCount ?? 0;
      items = result.items ?? [];

      if (items.isEmpty && page > 1 && totalCount > 0) {
        page = pageCount;
        await load();
        return;
      }
    } on UnauthorizedException {
      return;
    } on ApiClientException catch (e) {
      if (requestId != _requestId) {
        return;
      }
      error = e.message;
    } catch (e) {
      if (requestId != _requestId) {
        return;
      }
      debugPrint('Neočekivan odgovor za ${_provider.endpoint}: $e');
      error = 'Odgovor servera nije moguće pročitati.';
    }

    isLoading = false;
    _notify();
  }

  void search(Map<String, dynamic> filter) {
    _filter = filter;
    page = 1;
    load();
  }

  void goToPage(int newPage) {
    if (newPage < 1 || newPage > pageCount || newPage == page) {
      return;
    }
    page = newPage;
    load();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
