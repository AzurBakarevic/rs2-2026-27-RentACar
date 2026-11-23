import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/vehicle.dart';
import '../providers/category_provider.dart';
import '../providers/fuel_type_provider.dart';
import '../providers/transmission_type_provider.dart';
import '../providers/vehicle_model_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/crud_list_view.dart';
import '../widgets/data_table_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/vehicle_search_field.dart';
import 'vehicle_details_screen.dart';

class VehicleListScreen extends StatelessWidget {
  const VehicleListScreen({super.key});

  static const String title = 'Vozila';

  @override
  Widget build(BuildContext context) {
    final provider = context.read<VehicleProvider>();
    return MasterScreen(
      title: title,
      child: CrudListView<Vehicle>(
        provider: provider,
        idOf: (item) => item.id,
        searchKey: 'text',
        labels: CrudListLabels(
          searchHint: 'po marki, modelu ili registraciji',
          newItem: 'Novo vozilo',
          deleteQuestion: (item) => 'Da li želite obrisati vozilo „${vehicleLabel(item)}”?',
          saved: 'Vozilo je sačuvano.',
          deleted: 'Vozilo je obrisano.',
        ),
        columns: const [
          TableColumnDef('Slika'),
          TableColumnDef('Vozilo', flex: 2),
          TableColumnDef('Registracija'),
          TableColumnDef('Kategorija'),
          TableColumnDef('Cijena po danu'),
          TableColumnDef('Status'),
        ],
        cells: (item) => [
          VehicleImage(vehicleId: item.id, hasImage: item.hasImage, provider: provider, width: 112, height: 64),
          Text(item.name),
          Text(item.registrationNumber),
          Text(item.categoryName),
          Text(formatMoney(item.pricePerDay)),
          StatusBadge(active: item.isActive, activeLabel: 'Aktivno', inactiveLabel: 'Neaktivno'),
        ],
        openForm: (context, item) async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => VehicleDetailsScreen(vehicle: item)),
          );
          return saved ?? false;
        },
        newBlockedReason: () => _newBlockedReason(context),
        deleteBlockedReason: (item) => item.deleteBlockedReason,
      ),
    );
  }

  static Future<String?> _newBlockedReason(BuildContext context) async {
    final exists = await Future.wait([
      context.read<VehicleModelProvider>().hasAny(),
      context.read<CategoryProvider>().hasAny(),
      context.read<FuelTypeProvider>().hasAny(),
      context.read<TransmissionTypeProvider>().hasAny(),
    ]);
    const names = ['model vozila', 'kategoriju', 'vrstu goriva', 'vrstu mjenjača'];
    final missing = [
      for (var i = 0; i < names.length; i++)
        if (!exists[i]) names[i],
    ];
    return missing.isEmpty ? null : 'Prvo u Šifarnicima dodajte: ${missing.join(', ')}.';
  }
}

class VehicleImage extends StatelessWidget {
  const VehicleImage({
    super.key,
    required this.vehicleId,
    required this.hasImage,
    required this.provider,
    required this.width,
    required this.height,
  });

  final int vehicleId;
  final bool hasImage;
  final VehicleProvider provider;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: hasImage
            ? Image.network(
                provider.imageUrl(vehicleId),
                headers: provider.imageHeaders(),
                fit: BoxFit.cover,
                cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
                errorBuilder: (_, _, _) => const ImagePlaceholder(),
              )
            : const ImagePlaceholder(),
      ),
    );
  }
}

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
    );
  }
}
