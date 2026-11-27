import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../providers/notification_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_page.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  static const String title = 'Notifikacije';

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  static const int _pageSize = 20;
  static const int _maxReloadPages = 5;
  static const double _loadMoreOffset = 300;

  final ScrollController _scrollController = ScrollController();
  final Set<int> _markingIds = {};
  late final NotificationProvider _provider;

  List<AppNotification> _notifications = [];
  int _totalCount = 0;
  int _page = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  bool _isMarkingAll = false;
  String? _error;
  int _requestId = 0;

  bool get _hasMore => _notifications.length < _totalCount;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _provider = context.read<NotificationProvider>()..addListener(_onNotificationsChanged);
    _load();
  }

  @override
  void dispose() {
    _provider.removeListener(_onNotificationsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;
    final canMarkAll = !_isMarkingAll && (unreadCount > 0 || _notifications.any((x) => !x.isRead));
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: TabTitle(NotificationListScreen.title),
                    ),
                  ),
                  TextButton(
                    onPressed: canMarkAll ? _markAllAsRead : null,
                    child: _isMarkingAll
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Označi sve kao pročitano'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 3,
              child: _isLoading && _notifications.isNotEmpty ? const LinearProgressIndicator() : null,
            ),
            Expanded(child: RefreshIndicator(onRefresh: _refresh, child: _buildResults())),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final error = _error;
    if (error != null && _notifications.isEmpty) {
      return _buildMessageList([
        Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
        const SizedBox(height: 12),
        Center(child: OutlinedButton(onPressed: _load, child: const Text('Pokušaj ponovo'))),
      ]);
    }

    if (_notifications.isEmpty) {
      if (_isLoading) {
        return _buildMessageList([const Center(child: CircularProgressIndicator())]);
      }
      return _buildMessageList([
        const Text(
          'Nemate notifikacija.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
      ]);
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return _buildFooter();
        }
        final notification = _notifications[index];
        return _NotificationTile(
          notification: notification,
          isMarking: _markingIds.contains(notification.id),
          onMarkAsRead: () => _markAsRead(notification),
        );
      },
    );
  }

  Widget _buildFooter() {
    if (_loadMoreFailed) {
      return Center(child: TextButton(onPressed: _loadMore, child: const Text('Učitaj još notifikacija')));
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMessageList(List<Widget> children) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: children,
    );
  }

  void _onNotificationsChanged() {
    final latestUnreadId = _provider.latestUnreadId;
    if (latestUnreadId != null && !_notifications.any((x) => x.id == latestUnreadId)) {
      _load();
    }
  }

  Future<void> _refresh() async {
    _provider.refresh();
    await _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    final pages = _page.clamp(1, _maxReloadPages);
    setState(() {
      _error = null;
      _isLoading = true;
      _isLoadingMore = false;
      _loadMoreFailed = false;
    });

    try {
      final result = await _provider.get(
        filter: {'page': 1, 'pageSize': pages * _pageSize, 'includeTotalCount': true},
      );
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _notifications = result.items ?? [];
        _totalCount = result.totalCount ?? _notifications.length;
        _page = pages;
      });
    } on UnauthorizedException catch (_) {
      return;
    } on ApiClientException catch (e) {
      _showLoadError(requestId, e.message);
    } catch (_) {
      _showLoadError(requestId, unexpectedResponseError);
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLoadError(int requestId, String message) {
    if (!mounted || requestId != _requestId) {
      return;
    }
    setState(() {
      _notifications = [];
      _totalCount = 0;
      _page = 0;
      _error = message;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    final requestId = _requestId;
    setState(() {
      _isLoadingMore = true;
      _loadMoreFailed = false;
    });

    try {
      final result = await _provider.get(filter: {'page': _page + 1, 'pageSize': _pageSize, 'includeTotalCount': true});
      if (!mounted || requestId != _requestId) {
        return;
      }
      final loadedIds = _notifications.map((x) => x.id).toSet();
      setState(() {
        _notifications = [..._notifications, ...?result.items?.where((x) => !loadedIds.contains(x.id))];
        _totalCount = result.totalCount ?? _totalCount;
        _page++;
      });
    } on UnauthorizedException catch (_) {
      return;
    } on ApiClientException catch (e) {
      _showLoadMoreError(requestId, e.message);
    } catch (_) {
      _showLoadMoreError(requestId, unexpectedResponseError);
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _showLoadMoreError(int requestId, String message) {
    if (!mounted || requestId != _requestId) {
      return;
    }
    setState(() => _loadMoreFailed = true);
    showSnack(context, message);
  }

  void _onScroll() {
    if (_loadMoreFailed || !_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreOffset) {
      _loadMore();
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead || _markingIds.contains(notification.id)) {
      return;
    }
    setState(() => _markingIds.add(notification.id));
    try {
      await _provider.markAsRead(notification.id);
      if (mounted) {
        setState(() {
          _notifications = [for (final x in _notifications) x.id == notification.id ? x.asRead() : x];
        });
      }
    } on UnauthorizedException catch (_) {
      return;
    } on ApiClientException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        showSnack(context, unexpectedResponseError);
      }
    } finally {
      if (mounted) {
        setState(() => _markingIds.remove(notification.id));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAll = true);
    try {
      await _provider.markAllAsRead();
      if (mounted) {
        setState(() => _notifications = [for (final x in _notifications) x.asRead()]);
      }
    } on UnauthorizedException catch (_) {
      return;
    } on ApiClientException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        showSnack(context, unexpectedResponseError);
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.isMarking, required this.onMarkAsRead});

  final AppNotification notification;
  final bool isMarking;
  final VoidCallback onMarkAsRead;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return Semantics(
      button: isUnread,
      hint: isUnread ? 'Označi kao pročitano' : null,
      child: InkWell(
        onTap: isUnread && !isMarking ? onMarkAsRead : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 30,
                color: isUnread ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(notification.message, style: const TextStyle(fontSize: 15, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Text(
                      formatDateTime(notification.createdAt),
                      style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: isMarking
                      ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : Semantics(
                          label: 'Nepročitano',
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
