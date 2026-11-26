import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class VehicleImage extends StatelessWidget {
  const VehicleImage({
    super.key,
    required this.vehicle,
    this.width,
    required this.height,
    this.borderRadius = 12,
    this.iconSize = 36,
  });

  final Vehicle vehicle;
  final double? width;
  final double height;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = width ?? constraints.maxWidth;
        final placeholder = ColoredBox(
          color: AppColors.imagePlaceholder,
          child: Center(
            child: Icon(Icons.image_outlined, size: iconSize, color: AppColors.imagePlaceholderIcon),
          ),
        );

        Widget child = placeholder;
        if (vehicle.hasImage) {
          final provider = context.read<VehicleProvider>();
          child = Image.network(
            provider.imageUrl(vehicle.id),
            headers: provider.imageHeaders(),
            fit: BoxFit.cover,
            cacheWidth: (imageWidth * MediaQuery.devicePixelRatioOf(context)).round(),
            loadingBuilder: (_, image, progress) => progress == null ? image : placeholder,
            errorBuilder: (_, _, _) => placeholder,
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(width: imageWidth, height: height, child: child),
        );
      },
    );
  }
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge(this.name, {super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.avatarBackground, borderRadius: BorderRadius.circular(8)),
      child: Text(name, style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

class AverageRating extends StatelessWidget {
  const AverageRating({super.key, required this.rating, this.reviewCount});

  final double? rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final value = rating;
    if (value == null) {
      return const Text('Nema ocjena', style: TextStyle(fontSize: 14, color: AppColors.textMuted));
    }

    final text = reviewCount == null ? formatRating(value) : '${formatRating(value)} ($reviewCount)';
    return Semantics(
      label: 'Prosječna ocjena $text',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.rating, size: 22),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 15, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 20});

  static const int maxRating = 5;

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ocjena $rating od $maxRating',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < maxRating; i++)
            Icon(
              i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < rating ? AppColors.rating : AppColors.imagePlaceholderIcon,
              size: size,
            ),
        ],
      ),
    );
  }
}
