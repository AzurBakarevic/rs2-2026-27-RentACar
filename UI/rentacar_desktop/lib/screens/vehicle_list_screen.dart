import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/crud_list_view.dart';
import '../widgets/data_table_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/vehicle_search_field.dart';
import 'vehicle_details_screen.dart';

/// Vozila (prijava: „Upravljanje vozilima”): tabela sa slikom, pretraga po marki, modelu ili registraciji.
/// Vozilo s rezervacijama backend ne dozvoljava obrisati; umjesto toga se deaktivira.
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
          VehicleImage(vehicle: item, provider: provider, width: 112, height: 64),
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
      ),
    );
  }
}

/// Slika vozila sa servera ili ikona kad vozilo nema sliku (ili se slika ne može učitati).
class VehicleImage extends StatelessWidget {
  const VehicleImage({
    super.key,
    required this.vehicle,
    required this.provider,
    required this.width,
    required this.height,
  });

  final Vehicle vehicle;
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
        child: vehicle.hasImage
            ? Image.network(
                provider.imageUrl(vehicle.id),
                headers: provider.imageHeaders(),
                fit: BoxFit.cover,
                // Slika se dekodira u veličini u kojoj se prikazuje, ne u punoj rezoluciji.
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
