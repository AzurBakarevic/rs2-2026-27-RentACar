using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Exceptions;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

// Na čekanju: korisnik je plaća (u roku od 15 minuta) ili otkazuje, a administrator potvrđuje (samo plaćenu) ili odbija.
// Neplaćenu rezervaciju nakon isteka roka otkazuje pozadinski posao.
public class PendingReservationState : BaseReservationState
{
    private readonly ReservationPaymentHandler _paymentHandler;

    public PendingReservationState(RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser, IServiceProvider serviceProvider,
        ReservationPaymentHandler paymentHandler)
        : base(dbContext, authenticatedUser, serviceProvider)
    {
        _paymentHandler = paymentHandler;
    }

    // Prijava: potvrditi se može samo plaćena rezervacija. Plaćanje se prvo provjerava kod Stripe-a,
    // za slučaj da je korisnik platio, a aplikacija to nije stigla javiti serveru.
    public override async Task ConfirmAsync(Reservation reservation)
    {
        var payment = await _paymentHandler.SyncAsync(reservation);
        if (payment?.Status != PaymentStatus.Paid)
        {
            throw new ClientException("Potvrditi se može samo plaćena rezervacija.");
        }

        await ChangeStatusAsync(reservation, ReservationStatus.Confirmed, null, ReservationNotifications.Confirmed);
    }

    // Prijava: odbijena rezervacija prelazi u status Otkazana, uz obavezan razlog, a uplaćeni iznos se vraća.
    public override async Task RejectAsync(Reservation reservation, string reason)
    {
        await ChangeStatusAsync(reservation, ReservationStatus.Cancelled, reason,
            (r, vehicleName) => ReservationNotifications.Rejected(r, vehicleName, reason));

        await _paymentHandler.ReleaseAsync(reservation);
    }

    public override async Task CancelAsync(Reservation reservation, string? reason)
    {
        // Prijava: rezervaciju na čekanju administrator potvrđuje ili odbija; otkazati može samo potvrđenu.
        if (IsAdministrator)
        {
            throw new ClientException("Rezervaciju na čekanju odbijte umjesto otkazivanja.");
        }

        await CancelByCustomerAsync(reservation, reason);
        await _paymentHandler.ReleaseAsync(reservation);
    }

    // Prijava: rezervacija koja nije plaćena u roku od 15 minuta od kreiranja prelazi u status Otkazana.
    // Prije otkazivanja se provjerava Stripe: ako je korisnik platio, a aplikacija to nije javila, rezervacija ostaje.
    public override async Task<bool> ExpireAsync(Reservation reservation)
    {
        if (DateTime.UtcNow < PaymentRules.GetPaymentDeadline(reservation.CreatedAt))
        {
            return false;
        }

        var payment = await _paymentHandler.SyncAsync(reservation);
        if (payment?.Status == PaymentStatus.Paid)
        {
            return false;
        }

        await ChangeStatusAsync(reservation, ReservationStatus.Cancelled, PaymentRules.ExpiredReason, ReservationNotifications.Expired);
        await _paymentHandler.ReleaseAsync(reservation);

        return true;
    }

    public override List<string> GetAllowedActions(ReservationResponse reservation)
    {
        if (!IsAdministrator)
        {
            var actions = CustomerActions(reservation);

            // Dok rezervacija nije plaćena, a rok nije istekao, plaćanje se može (ponovo) pokrenuti iz detalja (prijava).
            if (!reservation.IsPaid && DateTime.UtcNow < reservation.PaymentDeadline)
            {
                actions.Insert(0, ReservationActions.Pay);
            }

            return actions;
        }

        return reservation.IsPaid
            ? [ReservationActions.Confirm, ReservationActions.Reject]
            : [ReservationActions.Reject];
    }
}
