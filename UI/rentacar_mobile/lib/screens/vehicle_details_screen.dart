import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/review.dart';
import '../models/vehicle.dart';
import '../providers/review_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/rental_period.dart';
import '../utils/utils_widgets.dart';
import '../widgets/detail_row.dart';
import '../widgets/form_page.dart';
import '../widgets/vehicle_widgets.dart';
import 'reservation_create_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key, required this.vehicle, required this.period});

  final Vehicle vehicle;
  final RentalPeriod period;

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  static const int _reviewPageSize = 5;

  late Vehicle _vehicle = widget.vehicle;
  List<Review> _reviews = [];
  int _reviewTotal = 0;
  int _reviewPage = 0;
  bool _isLoadingReviews = true;
  bool _isLoadingMoreReviews = false;
  String? _reviewsError;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _vehicle;
    final description = vehicle.description;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              const Align(alignment: Alignment.centerLeft, child: AppBackButton()),
              const SizedBox(height: 12),
              VehicleImage(vehicle: vehicle, height: 200, borderRadius: 16, iconSize: 64),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      vehicle.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: AverageRating(rating: vehicle.averageRating, reviewCount: vehicle.reviewCount),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: CategoryBadge(vehicle.categoryName)),
              if (description != null) ...[
                const SizedBox(height: 12),
                Text(description, style: const TextStyle(fontSize: 16, height: 1.4, color: AppColors.textDark)),
              ],
              const SizedBox(height: 16),
              DetailRow(
                icon: Icons.local_gas_station_outlined,
                label: 'Gorivo',
                value: vehicle.fuelTypeName,
                isFirst: true,
              ),
              DetailRow(icon: Icons.settings_outlined, label: 'Mjenjač', value: vehicle.transmissionTypeName),
              DetailRow(icon: Icons.event_seat_outlined, label: 'Sjedišta', value: '${vehicle.seatCount}'),
              DetailRow(icon: Icons.calendar_today_outlined, label: 'Godište', value: '${vehicle.productionYear}'),
              DetailRow(
                icon: Icons.payments_outlined,
                label: 'Cijena po danu',
                value: formatMoney(vehicle.pricePerDay),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recenzije',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              ..._buildReviews(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: FilledButton(onPressed: _openReservation, child: const Text('Rezerviši')),
          ),
        ),
      ),
    );
  }

  void _openReservation() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReservationCreateScreen(vehicle: _vehicle, period: widget.period)),
    );
  }

  List<Widget> _buildReviews() {
    if (_reviews.isEmpty) {
      if (_isLoadingReviews) {
        return const [
          Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        ];
      }

      final error = _reviewsError;
      if (error != null) {
        return [
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: _loadReviews, child: const Text('Pokušaj ponovo')),
          ),
        ];
      }

      return const [
        SizedBox(height: 8),
        Text('Vozilo još nema recenzija.', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
      ];
    }

    return [
      for (final review in _reviews) _ReviewTile(review: review),
      if (_reviews.length < _reviewTotal)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _isLoadingMoreReviews
              ? const Center(child: CircularProgressIndicator())
              : Center(child: TextButton(onPressed: _loadMoreReviews, child: const Text('Prikaži još recenzija'))),
        ),
    ];
  }

  Future<void> _refresh() async {
    await Future.wait([_reloadVehicle(), _loadReviews()]);
  }

  Future<void> _reloadVehicle() async {
    try {
      final vehicle = await context.read<VehicleProvider>().getById(_vehicle.id);
      if (mounted) {
        setState(() => _vehicle = vehicle);
      }
    } on ApiClientException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        showSnack(context, unexpectedResponseError);
      }
    }
  }

  Map<String, dynamic> _reviewFilter(int page) {
    return {'vehicleId': _vehicle.id, 'page': page, 'pageSize': _reviewPageSize, 'includeTotalCount': true};
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
      _reviewsError = null;
    });

    try {
      final result = await context.read<ReviewProvider>().get(filter: _reviewFilter(1));
      if (!mounted) {
        return;
      }
      setState(() {
        _reviews = result.items ?? [];
        _reviewTotal = result.totalCount ?? _reviews.length;
        _reviewPage = 1;
      });
    } on ApiClientException catch (e) {
      _showReviewsError(e.message);
    } catch (_) {
      _showReviewsError(unexpectedResponseError);
    } finally {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  void _showReviewsError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _reviews = [];
      _reviewTotal = 0;
      _reviewsError = message;
    });
  }

  Future<void> _loadMoreReviews() async {
    setState(() => _isLoadingMoreReviews = true);
    try {
      final result = await context.read<ReviewProvider>().get(filter: _reviewFilter(_reviewPage + 1));
      if (!mounted) {
        return;
      }
      setState(() {
        _reviews = [..._reviews, ...?result.items];
        _reviewTotal = result.totalCount ?? _reviewTotal;
        _reviewPage++;
      });
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
        setState(() => _isLoadingMoreReviews = false);
      }
    }
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final comment = review.comment;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
              ),
              RatingStars(rating: review.rating),
            ],
          ),
          if (comment != null && comment.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(comment, style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textDark)),
          ],
          const SizedBox(height: 6),
          Text(formatDate(review.createdAt), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
