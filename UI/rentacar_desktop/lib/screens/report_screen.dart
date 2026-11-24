import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../layouts/master_screen.dart';
import '../models/report.dart';
import '../providers/report_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/pdf_print.dart';
import '../utils/utils_widgets.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  static const String title = 'Izvještaji';

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const int _maxPeriodDays = 366;

  ReportType _type = ReportType.reservations;
  late DateTime _from;
  late DateTime _to;
  ReportFile? _report;
  String? _error;
  bool _isGenerating = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month);
    _to = DateTime(now.year, now.month + 1, 0);
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreen(
      title: ReportScreen.title,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(48, 48, 48, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final type in ReportType.values) ...[
                    if (type != ReportType.values.first) const SizedBox(width: 32),
                    Expanded(
                      child: _ReportTypeCard(
                        type: type,
                        selected: type == _type,
                        onTap: _isGenerating ? null : () => _selectType(type),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildPeriodPanel(),
            if (_report case final report?) ...[
              const SizedBox(height: 32),
              _buildResultPanel(report),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _type.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DateField(
                label: 'Od',
                value: _from,
                enabled: !_isGenerating,
                onChanged: (value) => _changePeriod(from: value),
              ),
              const SizedBox(width: 32),
              _DateField(
                label: 'Do',
                value: _to,
                enabled: !_isGenerating,
                onChanged: (value) => _changePeriod(to: value),
              ),
              const SizedBox(width: 32),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isGenerating ? null : _generate,
                  child: _isGenerating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Kreiraj izvještaj'),
                ),
              ),
            ],
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 16),
            Text(error, style: const TextStyle(fontSize: 15, color: AppColors.error)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultPanel(ReportFile report) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 40),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Izvještaj je kreiran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  report.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          OutlinedButton.icon(
            onPressed: _isBusy ? null : () => _download(report),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Preuzmi'),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: _isBusy ? null : () => _print(report),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Ispiši'),
          ),
        ],
      ),
    );
  }

  void _selectType(ReportType type) {
    if (type == _type) {
      return;
    }
    setState(() {
      _type = type;
      _report = null;
      _error = null;
    });
  }

  void _changePeriod({DateTime? from, DateTime? to}) {
    setState(() {
      _from = from ?? _from;
      _to = to ?? _to;
      _report = null;
      _error = null;
    });
  }

  String? _validatePeriod() {
    if (_to.isBefore(_from)) {
      return 'Datum do ne može biti prije datuma od.';
    }
    final from = DateTime.utc(_from.year, _from.month, _from.day);
    final to = DateTime.utc(_to.year, _to.month, _to.day);
    if (to.difference(from).inDays >= _maxPeriodDays) {
      return 'Izvještaj se može kreirati za period od najviše godinu dana.';
    }
    return null;
  }

  Future<void> _generate() async {
    final validationError = _validatePeriod();
    if (validationError != null) {
      setState(() {
        _error = validationError;
        _report = null;
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _report = null;
    });

    try {
      final report = await context.read<ReportProvider>().generate(_type, _from, _to);
      if (mounted) {
        setState(() => _report = report);
      }
    } on UnauthorizedException {
      return;
    } on ApiClientException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _download(ReportFile report) async {
    setState(() => _isBusy = true);
    try {
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Preuzimanje izvještaja',
        fileName: report.fileName,
        bytes: report.bytes,
        mimeType: 'application/pdf',
      );
      if (saved != null && mounted) {
        showSnack(context, 'Izvještaj je preuzet.');
      }
    } catch (e) {
      debugPrint('Preuzimanje izvještaja nije uspjelo: $e');
      if (mounted) {
        await alertBox(context, 'Greška', 'Izvještaj nije moguće sačuvati.');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _print(ReportFile report) async {
    setState(() => _isBusy = true);
    try {
      final printed = await printPdf(report.bytes, report.fileName);
      if (printed && mounted) {
        showSnack(context, 'Izvještaj je poslan na ispis.');
      }
    } catch (e) {
      debugPrint('Ispis izvještaja nije uspio: $e');
      if (mounted) {
        await alertBox(context, 'Greška', 'Izvještaj nije moguće ispisati.');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}

class _ReportTypeCard extends StatelessWidget {
  const _ReportTypeCard({required this.type, required this.selected, required this.onTap});

  final ReportType type;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.infoBackground : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Icon(
                  type == ReportType.reservations ? Icons.calendar_today_outlined : Icons.trending_up,
                  color: AppColors.primary,
                  size: 48,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      Text(type.description, style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: selected ? AppColors.primary : AppColors.border,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.enabled, required this.onChanged});

  final String label;
  final DateTime value;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: enabled ? () => _pick(context) : null,
            child: InputDecorator(
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: EdgeInsets.fromLTRB(16, 17, 8, 17),
                suffixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textMuted),
              ),
              child: Text(formatDate(value), style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }
}
