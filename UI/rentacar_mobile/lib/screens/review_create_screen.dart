import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/reservation.dart';
import '../providers/reservation_provider.dart';
import '../providers/review_provider.dart';
import '../utils/api_client_exception.dart';
import '../utils/app_theme.dart';
import '../utils/form_errors.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_page.dart';
import '../widgets/notice_box.dart';
import '../widgets/reservation_widgets.dart';
import '../widgets/vehicle_widgets.dart';

class ReviewCreateScreen extends StatefulWidget {
  const ReviewCreateScreen({super.key, required this.reservation});

  static const int maxRating = 5;
  static const int maxCommentLength = 1000;

  final Reservation reservation;

  @override
  State<ReviewCreateScreen> createState() => _ReviewCreateScreenState();
}

class _ReviewCreateScreenState extends State<ReviewCreateScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSaving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;
    return FormPage(
      title: 'Recenzija',
      child: FormBuilder(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  VehicleImage.byId(
                    vehicleId: reservation.vehicleId,
                    hasImage: reservation.vehicleHasImage,
                    width: 96,
                    height: 72,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                reservation.vehicleName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ReservationStatusBadge(reservation.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatDateRange(reservation.pickupAt, reservation.returnAt),
                          style: const TextStyle(fontSize: 15, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Ocjena'),
            FormBuilderField<int>(
              name: 'rating',
              validator: (value) => value == null ? 'Odaberite ocjenu od 1 do 5.' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 1; i <= ReviewCreateScreen.maxRating; i++)
                        IconButton(
                          tooltip: 'Ocjena $i',
                          iconSize: 44,
                          padding: const EdgeInsets.all(2),
                          onPressed: _isSaving ? null : () => field.didChange(i),
                          icon: Icon(
                            i <= (field.value ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: i <= (field.value ?? 0) ? AppColors.rating : AppColors.imagePlaceholderIcon,
                          ),
                        ),
                    ],
                  ),
                  if (field.errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            const SectionTitle('Komentar'),
            FormBuilderTextField(
              name: 'comment',
              minLines: 5,
              maxLines: 8,
              maxLength: ReviewCreateScreen.maxCommentLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Napišite svoje utiske o vozilu...'),
              validator: (value) => (value ?? '').trim().length > ReviewCreateScreen.maxCommentLength
                  ? 'Komentar može imati najviše ${ReviewCreateScreen.maxCommentLength} znakova.'
                  : null,
            ),
            const SizedBox(height: 16),
            NoticeBox(message: _error),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Pošalji recenziju'),
            ),
          ],
        ),
      ),
    );
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

    final comment = (form.value['comment'] as String? ?? '').trim();
    final reservations = context.read<ReservationProvider>();
    try {
      await context.read<ReviewProvider>().insert({
        'reservationId': widget.reservation.id,
        'rating': form.value['rating'],
        'comment': comment.isEmpty ? null : comment,
      });
      reservations.reservationChanged();
      if (mounted) {
        showSnack(context, 'Hvala na recenziji!');
        Navigator.of(context).pop(true);
      }
    } on ApiClientException catch (e) {
      _showError(applyServerErrors(form, e));
    } catch (_) {
      _showError(unexpectedResponseError);
    }
  }

  void _showError(String? message) {
    if (mounted) {
      setState(() {
        _isSaving = false;
        _error = message;
      });
    }
  }
}
