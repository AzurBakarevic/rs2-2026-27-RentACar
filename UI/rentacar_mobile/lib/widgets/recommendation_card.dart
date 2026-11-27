import 'package:material_ui/material_ui.dart';

import '../models/recommendation.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'vehicle_widgets.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({super.key, required this.recommendation, required this.onTap});

  final Recommendation recommendation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              VehicleImage.byId(
                vehicleId: recommendation.vehicleId,
                hasImage: recommendation.hasImage,
                width: 104,
                height: 84,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.vehicleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CategoryBadge(recommendation.categoryName),
                        Text(
                          formatPricePerDay(recommendation.pricePerDay),
                          style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recommendation.explanation,
                      style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
