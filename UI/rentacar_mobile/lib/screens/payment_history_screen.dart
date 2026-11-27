import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/payment_transaction.dart';
import '../providers/payment_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_page.dart';
import 'reservation_details_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  static const String title = 'Historija plaćanja';

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  static const int _pageSize = 20;
  static const double _loadMoreOffset = 300;

  final ScrollController _scrollController = ScrollController();

  List<PaymentTransaction> _transactions = [];
  int _totalCount = 0;
  int _page = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _loadMoreFailed = false;
  String? _error;
  int _requestId = 0;

  bool get _hasMore => _transactions.length < _totalCount;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: ScreenHeader(title: PaymentHistoryScreen.title),
            ),
            Expanded(child: RefreshIndicator(onRefresh: _load, child: _buildResults())),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final error = _error;
    if (error != null && _transactions.isEmpty) {
      return _buildMessageList([
        Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
        const SizedBox(height: 12),
        Center(child: OutlinedButton(onPressed: _load, child: const Text('Pokušaj ponovo'))),
      ]);
    }

    if (_transactions.isEmpty) {
      if (_isLoading) {
        return _buildMessageList([const Center(child: CircularProgressIndicator())]);
      }
      return _buildMessageList([
        const Text(
          'Nemate nijednu uplatu ni povrat.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
      ]);
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _transactions.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == _transactions.length) {
          return _buildFooter();
        }
        final transaction = _transactions[index];
        return _TransactionCard(transaction: transaction, onTap: () => _openReservation(transaction));
      },
    );
  }

  Widget _buildFooter() {
    if (_loadMoreFailed) {
      return Center(child: TextButton(onPressed: _loadMore, child: const Text('Učitaj još transakcija')));
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

  Map<String, dynamic> _buildFilter(int page) => {'page': page, 'pageSize': _pageSize, 'includeTotalCount': true};

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _error = null;
      _isLoading = true;
      _isLoadingMore = false;
      _loadMoreFailed = false;
    });

    try {
      final result = await context.read<PaymentProvider>().get(filter: _buildFilter(1));
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _transactions = result.items ?? [];
        _totalCount = result.totalCount ?? _transactions.length;
        _page = 1;
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
      _transactions = [];
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
      final result = await context.read<PaymentProvider>().get(filter: _buildFilter(_page + 1));
      if (!mounted || requestId != _requestId) {
        return;
      }
      setState(() {
        _transactions = [..._transactions, ...?result.items];
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

  void _openReservation(PaymentTransaction transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReservationDetailsScreen(reservationId: transaction.reservationId)),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, required this.onTap});

  final PaymentTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark);
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(transaction.vehicleName, style: titleStyle)),
                  const SizedBox(width: 12),
                  Text(formatMoney(transaction.amount), style: titleStyle),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatDateRange(transaction.pickupAt, transaction.returnAt),
                style: const TextStyle(fontSize: 15, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatDateTime(transaction.transactionAt),
                      style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                  ),
                  Text(
                    transaction.isRefund ? 'Vraćeno' : 'Plaćeno',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: transaction.isRefund ? AppColors.confirmed : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
