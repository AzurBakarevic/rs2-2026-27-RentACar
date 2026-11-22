import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/reservation.dart';
import '../providers/reservation_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/utils_widgets.dart';
import '../widgets/form_dialog.dart';

// Ista granica kao na backendu (ReservationReasonRules).
const int _maxReasonLength = 300;

/// Potvrda akcije nad rezervacijom (upute 6), uz razlog kod odbijanja i otkazivanja (prijava).
/// Vraća `true` ako je akcija izvršena.
Future<bool> showReservationActionDialog(BuildContext context, Reservation reservation, ReservationAction action) {
  final provider = context.read<ReservationProvider>();
  final (title, confirmLabel, question, consequence) = switch (action) {
    ReservationAction.confirm => (
        'Potvrda rezervacije',
        'Potvrdi',
        'Da li želite potvrditi ovu rezervaciju?',
        'Korisnik dobija obavijest i e-mail.',
      ),
    ReservationAction.reject => (
        'Odbijanje rezervacije',
        'Odbij',
        'Da li želite odbiti ovu rezervaciju?',
        '${reservation.isPaid ? 'Uplaćeni iznos se vraća korisniku. ' : ''}'
            'Rezervacija prelazi u status „Otkazana” i više se ne može mijenjati. '
            'Korisnik dobija obavijest i e-mail s razlogom.',
      ),
    ReservationAction.complete => (
        'Završetak najma',
        'Završi',
        'Da li je vozilo vraćeno i želite završiti najam?',
        'Završena rezervacija se više ne može mijenjati. Korisnik dobija obavijest.',
      ),
    ReservationAction.cancel => (
        'Otkazivanje rezervacije',
        'Otkaži rezervaciju',
        'Da li želite otkazati ovu rezervaciju?',
        '${reservation.isPaid ? 'Uplaćeni iznos se vraća korisniku. ' : ''}'
            'Otkazana rezervacija se više ne može mijenjati. '
            'Korisnik dobija obavijest i e-mail s razlogom.',
      ),
  };

  return showFormDialog(
    context,
    title: title,
    confirmLabel: confirmLabel,
    destructive: action.requiresReason,
    width: 480,
    focusField: 'reason',
    initialValue: {if (action.requiresReason) 'reason': ''},
    buildFields: (_) => [
      Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      _ReservationSummary(reservation),
      Text(consequence, style: const TextStyle(color: AppColors.textMuted)),
      if (action.requiresReason)
        FormBuilderTextField(
          name: 'reason',
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Razlog', alignLabelWithHint: true),
          validator: requiredText(
            action == ReservationAction.reject ? 'Razlog odbijanja je obavezan.' : 'Razlog otkazivanja je obavezan.',
            maxLength: _maxReasonLength,
            maxLengthMessage: 'Razlog može imati najviše $_maxReasonLength znakova.',
          ),
          valueTransformer: (value) => value?.trim(),
        ),
    ],
    onSave: (values) async {
      await provider.performAction(reservation.id, action, reason: values['reason'] as String?);
    },
  );
}

/// Poruka poslije uspješne akcije.
String reservationActionDone(ReservationAction action) => switch (action) {
      ReservationAction.confirm => 'Rezervacija je potvrđena.',
      ReservationAction.reject => 'Rezervacija je odbijena.',
      ReservationAction.complete => 'Rezervacija je završena.',
      ReservationAction.cancel => 'Rezervacija je otkazana.',
    };

class _ReservationSummary extends StatelessWidget {
  const _ReservationSummary(this.reservation);

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reservation.userFullName, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('${reservation.vehicleName} (${reservation.vehicleRegistrationNumber})'),
          Text('${formatDateTime(reservation.pickupAt)} – ${formatDateTime(reservation.returnAt)}'),
          Text(formatMoney(reservation.totalPrice)),
        ],
      ),
    );
  }
}
