import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/fuel_type.dart';
import '../models/transmission_type.dart';
import '../models/vehicle_model.dart';
import '../providers/brand_provider.dart';
import '../providers/category_provider.dart';
import '../providers/fuel_type_provider.dart';
import '../providers/transmission_type_provider.dart';
import '../providers/vehicle_model_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/field_with_add_button.dart';
import 'reference_data_dialog.dart';
import 'reference_data_tab.dart';

class ReferenceDataScreen extends StatelessWidget {
  const ReferenceDataScreen({super.key});

  static const String title = 'Šifarnici';

  @override
  Widget build(BuildContext context) {
    final brandProvider = context.read<BrandProvider>();
    return MasterScreen(
      title: title,
      child: DefaultTabController(
        length: 5,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: EdgeInsets.symmetric(horizontal: 32),
                tabs: [
                  Tab(text: 'Marke'),
                  Tab(text: 'Modeli'),
                  Tab(text: 'Kategorije'),
                  Tab(text: 'Gorivo'),
                  Tab(text: 'Mjenjač'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ReferenceDataTab<Brand>(
                      provider: context.read<BrandProvider>(),
                      labels: ReferenceDataLabels(
                        newItem: 'Nova marka',
                        editItem: 'Izmjena marke',
                        deleteQuestion: (name) => 'Da li želite obrisati marku „$name”?',
                        saved: 'Marka je sačuvana.',
                        deleted: 'Marka je obrisana.',
                      ),
                    ),
                    ReferenceDataTab<VehicleModel>(
                      provider: context.read<VehicleModelProvider>(),
                      labels: ReferenceDataLabels(
                        newItem: 'Novi model',
                        editItem: 'Izmjena modela',
                        deleteQuestion: (name) => 'Da li želite obrisati model „$name”?',
                        saved: 'Model je sačuvan.',
                        deleted: 'Model je obrisan.',
                      ),
                      extraColumns: const ['Marka'],
                      extraCells: (model) => [Text(model.brandName)],
                      openForm: _openModelForm,
                      newBlockedReason: () async =>
                          await brandProvider.hasAny() ? null : 'Prvo dodajte marku u kartici Marke.',
                    ),
                    ReferenceDataTab<Category>(
                      provider: context.read<CategoryProvider>(),
                      labels: ReferenceDataLabels(
                        newItem: 'Nova kategorija',
                        editItem: 'Izmjena kategorije',
                        deleteQuestion: (name) => 'Da li želite obrisati kategoriju „$name”?',
                        saved: 'Kategorija je sačuvana.',
                        deleted: 'Kategorija je obrisana.',
                      ),
                    ),
                    ReferenceDataTab<FuelType>(
                      provider: context.read<FuelTypeProvider>(),
                      labels: ReferenceDataLabels(
                        newItem: 'Nova vrsta goriva',
                        editItem: 'Izmjena vrste goriva',
                        deleteQuestion: (name) => 'Da li želite obrisati vrstu goriva „$name”?',
                        saved: 'Vrsta goriva je sačuvana.',
                        deleted: 'Vrsta goriva je obrisana.',
                      ),
                    ),
                    ReferenceDataTab<TransmissionType>(
                      provider: context.read<TransmissionTypeProvider>(),
                      labels: ReferenceDataLabels(
                        newItem: 'Nova vrsta mjenjača',
                        editItem: 'Izmjena vrste mjenjača',
                        deleteQuestion: (name) => 'Da li želite obrisati vrstu mjenjača „$name”?',
                        saved: 'Vrsta mjenjača je sačuvana.',
                        deleted: 'Vrsta mjenjača je obrisana.',
                      ),
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

  static Future<bool> _openModelForm(BuildContext context, VehicleModel? model) async {
    final modelProvider = context.read<VehicleModelProvider>();

    final brands = await context.read<BrandProvider>().get(filter: {'pageSize': 100});
    final brandItems = [
      for (final brand in brands.items ?? <Brand>[])
        DropdownMenuItem<int>(value: brand.id, child: Text(brand.name)),
    ];
    if (model != null && !brandItems.any((item) => item.value == model.brandId)) {
      brandItems.add(DropdownMenuItem<int>(value: model.brandId, child: Text(model.brandName)));
    }

    if (!context.mounted) {
      return false;
    }

    return showReferenceDataDialog(
      context,
      title: model == null ? 'Novi model' : 'Izmjena modela',
      initialValue: {'name': model?.name ?? '', 'brandId': model?.brandId},
      extraFields: [_BrandField(items: brandItems)],
      onSave: (values) async {
        if (model == null) {
          await modelProvider.insert(values);
        } else {
          await modelProvider.update(model.id, values);
        }
      },
    );
  }
}

class _BrandField extends StatefulWidget {
  const _BrandField({required this.items});

  final List<DropdownMenuItem<int>> items;

  @override
  State<_BrandField> createState() => _BrandFieldState();
}

class _BrandFieldState extends State<_BrandField> {
  late List<DropdownMenuItem<int>> _items = widget.items;
  bool _brandAdded = false;

  @override
  Widget build(BuildContext context) {
    return FieldWithAddButton(
      tooltip: 'Nova marka',
      onAdd: _addBrand,
      field: FormBuilderDropdown<int>(
        name: 'brandId',
        decoration: InputDecoration(
          labelText: 'Marka',
          helperText: _brandAdded ? 'Marka je sačuvana.' : null,
          helperStyle: const TextStyle(color: AppColors.success),
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(8),
        iconEnabledColor: AppColors.textMuted,
        items: _items,
        validator: (value) => value == null ? 'Marka je obavezna.' : null,
      ),
    );
  }

  Future<void> _addBrand() async {
    final brand = await showNewBrandDialog(context);
    if (brand == null || !mounted) {
      return;
    }
    setState(() {
      _items = [DropdownMenuItem<int>(value: brand.id, child: Text(brand.name)), ..._items];
      _brandAdded = true;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      FormBuilder.of(context)?.fields['brandId']?.didChange(brand.id);
    }
  }
}
