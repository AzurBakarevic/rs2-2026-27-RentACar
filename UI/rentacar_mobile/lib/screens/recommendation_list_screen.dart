import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/recommendation.dart';
import '../providers/recommendation_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/rental_period.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_page.dart';
import '../widgets/recommendation_card.dart';
import 'vehicle_details_screen.dart';

const String emptyRecommendationsMessage = 'Trenutno nema preporuka.';

bool _isOpeningVehicle = false;

Future<void> openRecommendedVehicle(BuildContext context, Recommendation recommendation) async {
  if (_isOpeningVehicle) {
    return;
  }
  _isOpeningVehicle = true;
  final navigator = Navigator.of(context);
  try {
    final vehicle = await context.read<VehicleProvider>().getById(recommendation.vehicleId);
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => VehicleDetailsScreen(vehicle: vehicle, period: RentalPeriod.initial(DateTime.now())),
      ),
    );
  } on UnauthorizedException catch (_) {
    return;
  } on ApiClientException catch (e) {
    if (context.mounted) {
      showSnack(context, e.message);
    }
  } catch (_) {
    if (context.mounted) {
      showSnack(context, unexpectedResponseError);
    }
  } finally {
    _isOpeningVehicle = false;
  }
}

class RecommendationListScreen extends StatefulWidget {
  const RecommendationListScreen({super.key, required this.initial});

  static const String title = 'Preporuke za vas';

  final List<Recommendation> initial;

  @override
  State<RecommendationListScreen> createState() => _RecommendationListScreenState();
}

class _RecommendationListScreenState extends State<RecommendationListScreen> {
  late List<Recommendation> _recommendations = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            itemCount: _recommendations.isEmpty ? 2 : _recommendations.length + 1,
            separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 24 : 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return const ScreenHeader(title: RecommendationListScreen.title);
              }
              if (_recommendations.isEmpty) {
                return const Text(
                  emptyRecommendationsMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                );
              }
              final recommendation = _recommendations[index - 1];
              return RecommendationCard(
                recommendation: recommendation,
                onTap: () => openRecommendedVehicle(context, recommendation),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    try {
      final recommendations = await context.read<RecommendationProvider>().getRecommendations();
      if (mounted) {
        setState(() => _recommendations = recommendations);
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
    }
  }
}
