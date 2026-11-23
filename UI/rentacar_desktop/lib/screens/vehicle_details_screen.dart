import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/named_entity.dart';
import '../models/search_result.dart';
import '../models/vehicle.dart';
import '../providers/brand_provider.dart';
import '../providers/category_provider.dart';
import '../providers/fuel_type_provider.dart';
import '../providers/transmission_type_provider.dart';
import '../providers/vehicle_model_provider.dart';
import '../providers/vehicle_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/form_errors.dart';
import '../utils/form_validators.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/field_with_add_button.dart';
import '../widgets/form_close_button.dart';
import 'reference_data_dialog.dart';
import 'vehicle_list_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  static const int _maxImageBytes = 2 * 1024 * 1024;
  static const Map<String, String> _imageContentTypes = {'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png'};

  static const Map<String, dynamic> _referenceFilter = {'pageSize': 100};

  final _formKey = GlobalKey<FormBuilderState>();

  Vehicle? _vehicle;

  bool _wasSaved = false;

  List<DropdownMenuItem<int>> _brands = [];
  List<DropdownMenuItem<int>> _models = [];
  List<DropdownMenuItem<int>> _categories = [];
  List<DropdownMenuItem<int>> _fuelTypes = [];
  List<DropdownMenuItem<int>> _transmissionTypes = [];
  int? _brandId;
  int _modelsRequestId = 0;
  bool _isLoadingModels = false;
  bool _modelsFailed = false;

  bool _isLoading = true;
  String? _loadError;
  bool _isSaving = false;
  String? _error;

  Uint8List? _imageBytes;
  String? _imageName;
  String? _imageContentType;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _brandId = widget.vehicle?.brandId;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final vehicle = _vehicle;
    try {
      final results = await Future.wait<SearchResult<NamedEntity>>([
        context.read<BrandProvider>().get(filter: _referenceFilter),
        context.read<CategoryProvider>().get(filter: _referenceFilter),
        context.read<FuelTypeProvider>().get(filter: _referenceFilter),
        context.read<TransmissionTypeProvider>().get(filter: _referenceFilter),
        if (vehicle != null)
          context.read<VehicleModelProvider>().get(filter: {..._referenceFilter, 'brandId': vehicle.brandId}),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _brands = _toItems(results[0], vehicle?.brandId, vehicle?.brandName);
        _categories = _toItems(results[1], vehicle?.categoryId, vehicle?.categoryName);
        _fuelTypes = _toItems(results[2], vehicle?.fuelTypeId, vehicle?.fuelTypeName);
        _transmissionTypes = _toItems(results[3], vehicle?.transmissionTypeId, vehicle?.transmissionTypeName);
        _models = vehicle == null ? [] : _toItems(results[4], vehicle.vehicleModelId, vehicle.vehicleModelName);
        _isLoading = false;
      });
    } on UnauthorizedException catch (_) {
    } on ApiClientException catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.message;
          _isLoading = false;
        });
      }
    }
  }

  static List<DropdownMenuItem<int>> _toItems(SearchResult<NamedEntity> result, int? currentId, String? currentName) {
    final items = [
      for (final item in result.items ?? <NamedEntity>[])
        DropdownMenuItem<int>(value: item.id, child: Text(item.name)),
    ];
    if (currentId != null && !items.any((item) => item.value == currentId)) {
      items.add(DropdownMenuItem<int>(value: currentId, child: Text(currentName ?? '')));
    }
    return items;
  }

  Future<void> _onBrandChanged(int? brandId) async {
    final requestId = ++_modelsRequestId;
    _formKey.currentState?.fields['vehicleModelId']?.didChange(null);
    setState(() {
      if (_modelsFailed) {
        _error = null;
      }
      _brandId = brandId;
      _models = [];
      _isLoadingModels = brandId != null;
      _modelsFailed = false;
    });
    if (brandId == null) {
      return;
    }

    try {
      final result = await context.read<VehicleModelProvider>().get(filter: {..._referenceFilter, 'brandId': brandId});
      if (!mounted || requestId != _modelsRequestId) {
        return;
      }
      setState(() {
        _models = _toItems(result, null, null);
        _isLoadingModels = false;
      });
    } on UnauthorizedException catch (_) {
    } on ApiClientException catch (e) {
      _showModelsError(requestId, e.message);
    } catch (e) {
      debugPrint('Učitavanje modela nije uspjelo: $e');
      _showModelsError(requestId, 'Odgovor servera nije moguće pročitati.');
    }
  }

  void _showModelsError(int requestId, String message) {
    if (mounted && requestId == _modelsRequestId) {
      setState(() {
        _isLoadingModels = false;
        _modelsFailed = true;
        _error = message;
      });
    }
  }

  String? get _modelsHint {
    if (_isLoadingModels) {
      return 'Učitavanje...';
    }
    if (_brandId == null) {
      return 'Prvo odaberite marku';
    }
    if (_modelsFailed) {
      return 'Modeli nisu učitani';
    }
    return _models.isEmpty ? 'Marka nema modela' : null;
  }

  String? get _addModelBlockedReason {
    if (_isSaving) {
      return savingInProgressReason;
    }
    if (_brandId == null) {
      return 'Prvo odaberite marku.';
    }
    if (_isLoadingModels) {
      return 'Sačekajte da se modeli učitaju.';
    }
    return _modelsFailed ? 'Modeli nisu učitani. Ponovo odaberite marku.' : null;
  }

  Future<void> _addBrand() async {
    final brand = await showNewBrandDialog(context);
    if (brand == null || !mounted) {
      return;
    }
    setState(() => _brands = [DropdownMenuItem<int>(value: brand.id, child: Text(brand.name)), ..._brands]);
    await _selectAdded('brandId', brand.id, 'Marka je sačuvana.');
  }

  Future<void> _addModel() async {
    final brandId = _brandId!;
    final model = await showNewVehicleModelDialog(
      context,
      brandId: brandId,
      brandName: _brands.firstWhere((item) => item.value == brandId).child,
    );
    if (model == null || !mounted) {
      return;
    }
    setState(() => _models = [DropdownMenuItem<int>(value: model.id, child: Text(model.name)), ..._models]);
    await _selectAdded('vehicleModelId', model.id, 'Model je sačuvan.');
  }

  Future<void> _selectAdded(String field, int id, String message) async {
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      _formKey.currentState?.fields[field]?.didChange(id);
      showSnack(context, message);
    }
  }

  void _close() => Navigator.pop(context, _wasSaved);

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: _vehicle == null ? 'Novo vozilo' : 'Izmjena vozila',
      menuLabel: VehicleListScreen.title,
      onBack: _close,
      navigationBlockedReason: _isSaving ? savingInProgressReason : null,
      child: Stack(
        children: [
          Positioned.fill(child: _buildBody()),
          Positioned(top: 8, right: 16, child: FormCloseButton(isSaving: _isSaving, onClose: _close)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
          ],
        ),
      );
    }

    final vehicle = widget.vehicle;
    final modelInList = _models.any((item) => item.value == vehicle?.vehicleModelId);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(64, 32, 64, 32),
      child: FormBuilder(
        key: _formKey,
        initialValue: {
          'brandId': vehicle?.brandId,
          'vehicleModelId': modelInList ? vehicle?.vehicleModelId : null,
          'categoryId': vehicle?.categoryId,
          'fuelTypeId': vehicle?.fuelTypeId,
          'transmissionTypeId': vehicle?.transmissionTypeId,
          'registrationNumber': vehicle?.registrationNumber ?? '',
          'productionYear': vehicle == null ? '' : '${vehicle.productionYear}',
          'seatCount': vehicle == null ? '' : '${vehicle.seatCount}',
          'pricePerDay': vehicle == null ? '' : formatDecimalInput(vehicle.pricePerDay),
          'description': vehicle?.description ?? '',
          'isActive': vehicle?.isActive ?? true,
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildError(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildFields()),
                const SizedBox(width: 48),
                SizedBox(width: 360, child: _buildImagePanel()),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSaving ? null : _close,
                  child: const Text('Odustani'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Sačuvaj'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields() {
    final currentYear = DateTime.now().year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(
          FieldWithAddButton(
            tooltip: 'Nova marka',
            blockedReason: _isSaving ? savingInProgressReason : null,
            onAdd: _addBrand,
            field: _dropdown(
              name: 'brandId',
              label: 'Marka',
              items: _brands,
              requiredMessage: 'Marka je obavezna.',
              onChanged: _onBrandChanged,
            ),
          ),
          FieldWithAddButton(
            tooltip: 'Novi model',
            blockedReason: _addModelBlockedReason,
            onAdd: _addModel,
            field: _dropdown(
              name: 'vehicleModelId',
              label: 'Model',
              items: _models,
              requiredMessage: 'Model je obavezan.',
              hint: _modelsHint,
            ),
          ),
        ),
        _row(
          _dropdown(name: 'categoryId', label: 'Kategorija', items: _categories, requiredMessage: 'Kategorija je obavezna.'),
          FormBuilderTextField(
            name: 'registrationNumber',
            decoration: const InputDecoration(labelText: 'Registracija', hintText: 'npr. A12-K-345'),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) {
                return 'Registracija je obavezna.';
              }
              if (text.length > 20) {
                return 'Registracija može imati najviše 20 znakova.';
              }
              if (!RegExp(r'^[A-Za-z0-9 -]+$').hasMatch(text)) {
                return 'Registracija smije sadržavati samo slova bez kvačica, brojeve, razmak i crticu.';
              }
              return null;
            },
            valueTransformer: (value) => value?.trim(),
          ),
        ),
        _row(
          _dropdown(name: 'fuelTypeId', label: 'Vrsta goriva', items: _fuelTypes, requiredMessage: 'Vrsta goriva je obavezna.'),
          _dropdown(
            name: 'transmissionTypeId',
            label: 'Vrsta mjenjača',
            items: _transmissionTypes,
            requiredMessage: 'Vrsta mjenjača je obavezna.',
          ),
        ),
        _row(
          FormBuilderTextField(
            name: 'productionYear',
            decoration: const InputDecoration(labelText: 'Godina proizvodnje'),
            validator: integerValidator(
              requiredMessage: 'Godina proizvodnje je obavezna.',
              min: 1990,
              max: currentYear + 1,
              rangeMessage: 'Godina proizvodnje mora biti između 1990 i ${currentYear + 1}.',
            ),
            valueTransformer: (value) => int.tryParse(value?.trim() ?? ''),
          ),
          FormBuilderTextField(
            name: 'seatCount',
            decoration: const InputDecoration(labelText: 'Broj sjedišta'),
            validator: integerValidator(
              requiredMessage: 'Broj sjedišta je obavezan.',
              min: 1,
              max: 9,
              rangeMessage: 'Broj sjedišta mora biti između 1 i 9.',
            ),
            valueTransformer: (value) => int.tryParse(value?.trim() ?? ''),
          ),
        ),
        _row(
          FormBuilderTextField(
            name: 'pricePerDay',
            decoration: const InputDecoration(labelText: 'Cijena po danu', suffixText: 'KM'),
            validator: decimalValidator(
              requiredMessage: 'Cijena po danu je obavezna.',
              decimalsMessage: 'Cijena po danu može imati najviše dvije decimale.',
              range: (value) => value <= 0
                  ? 'Cijena po danu mora biti veća od 0.'
                  : value > 10000
                      ? 'Cijena po danu može biti najviše 10000 KM.'
                      : null,
            ),
            valueTransformer: parseDecimal,
          ),
          FormBuilderSwitch(
            name: 'isActive',
            title: Text('Aktivno (nudi se u mobilnoj aplikaciji)'),
            decoration: plainFieldDecoration,
          ),
        ),
        FormBuilderTextField(
          name: 'description',
          decoration: const InputDecoration(labelText: 'Opis', alignLabelWithHint: true),
          minLines: 3,
          maxLines: 6,
          validator: maxLengthText(1000, 'Opis može imati najviše 1000 znakova.'),
          valueTransformer: (value) => (value?.trim().isEmpty ?? true) ? null : value!.trim(),
        ),
      ],
    );
  }

  Widget _row(Widget left, Widget right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 24),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String name,
    required String label,
    required List<DropdownMenuItem<int>> items,
    required String requiredMessage,
    ValueChanged<int?>? onChanged,
    String? hint,
  }) {
    return FormBuilderDropdown<int>(
      name: name,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: hint == null ? null : FloatingLabelBehavior.always,
      ),
      disabledHint: hint == null
          ? null
          : FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(hint)),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(8),
      iconEnabledColor: AppColors.textMuted,
      items: items,
      selectedItemBuilder: (_) => [
        for (final item in items)
          DefaultTextStyle.merge(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: Align(alignment: Alignment.centerLeft, child: item.child),
          ),
      ],
      validator: requiredValue(requiredMessage),
      onChanged: onChanged,
    );
  }

  Widget _buildImagePanel() {
    final Widget preview;
    if (_imageBytes != null) {
      preview = Image.memory(_imageBytes!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ImagePlaceholder());
    } else if (_vehicle?.hasImage ?? false) {
      preview = VehicleImage(
        vehicleId: _vehicle!.id,
        hasImage: true,
        provider: context.read<VehicleProvider>(),
        width: 360,
        height: 240,
      );
    } else {
      preview = const ImagePlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Slika vozila', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(height: 240, child: preview)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isSaving ? null : _pickImage,
          icon: const Icon(Icons.upload_outlined),
          label: Text(_imageBytes != null || (_vehicle?.hasImage ?? false) ? 'Promijeni sliku' : 'Odaberi sliku'),
        ),
        const SizedBox(height: 8),
        Text(
          _imageName == null ? 'JPG ili PNG, najviše 2 MB.' : 'Odabrano: $_imageName (sprema se uz vozilo)',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        if (_imageError != null) ...[
          const SizedBox(height: 8),
          Text(_imageError!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
  }

  Widget _buildError() {
    if (_error == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.errorBackground, borderRadius: BorderRadius.circular(8)),
      child: Text(_error!, style: const TextStyle(color: AppColors.error)),
    );
  }

  Future<void> _pickImage() async {
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        dialogTitle: 'Odaberite sliku vozila',
        type: FileType.custom,
        allowedExtensions: _imageContentTypes.keys.toList(),
      );
    } catch (e) {
      debugPrint('Odabir slike nije uspio: $e');
      if (mounted) {
        setState(() => _imageError = 'Odabir slike nije uspio.');
      }
      return;
    }
    if (file == null || !mounted) {
      return;
    }

    final contentType = _imageContentTypes[file.extension?.toLowerCase()];
    if (contentType == null) {
      setState(() => _imageError = 'Dozvoljene su samo slike u formatu JPG ili PNG.');
      return;
    }
    final length = await file.length();
    if (!mounted) {
      return;
    }
    if (length != null && length > _maxImageBytes) {
      setState(() => _imageError = 'Slika može imati najviše 2 MB.');
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    if (bytes.isEmpty || bytes.length > _maxImageBytes) {
      setState(() => _imageError = bytes.isEmpty ? 'Odabrani fajl je prazan.' : 'Slika može imati najviše 2 MB.');
      return;
    }

    setState(() {
      _imageBytes = bytes;
      _imageName = file!.name;
      _imageContentType = contentType;
      _imageError = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    final form = _formKey.currentState!;
    clearServerErrors(form);
    if (!form.saveAndValidate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final provider = context.read<VehicleProvider>();
    final values = Map<String, dynamic>.from(form.value)..remove('brandId');
    try {
      final current = _vehicle;
      _vehicle = current == null ? await provider.insert(values) : await provider.update(current.id, values);
      _wasSaved = true;
    } on UnauthorizedException {
      return;
    } on ApiClientException catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = applyServerErrors(form, e);
        });
        focusFirstError(form, 'brandId');
      }
      return;
    } catch (e) {
      debugPrint('Spremanje vozila nije uspjelo: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = unexpectedSaveError;
        });
      }
      return;
    }

    if (_imageBytes != null) {
      try {
        await provider.updateImage(_vehicle!.id, _imageBytes!, fileName: _imageName!, contentType: _imageContentType!);
        PaintingBinding.instance.imageCache
          ..clear()
          ..clearLiveImages();
      } on UnauthorizedException {
        return;
      } on ApiClientException catch (e) {
        _showImageSaveError(e.message);
        return;
      } catch (e) {
        debugPrint('Spremanje slike nije uspjelo: $e');
        _showImageSaveError('neočekivana greška.');
        return;
      }
    }

    if (mounted) {
      closeForm(context, saved: true);
    }
  }

  void _showImageSaveError(String message) {
    if (mounted) {
      setState(() {
        _isSaving = false;
        _error = 'Podaci vozila su sačuvani, ali slika nije: $message';
      });
    }
  }
}
