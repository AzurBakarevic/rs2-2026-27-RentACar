using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Exceptions;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

// Potvrđena: administrator je nakon vraćanja vozila označava kao završenu ili je izuzetno otkazuje,
// a korisnik je može otkazati najkasnije 24 sata prije preuzimanja. Pri otkazivanju se uplata vraća u cijelosti.
public class ConfirmedReservationState : BaseReservationState
{
    private readonly ReservationPaymentHandler _paymentHandler;

    public ConfirmedReservationState(RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser, IServiceProvider serviceProvider,
        ReservationPaymentHandler paymentHandler)
        : base(dbContext, authenticatedUser, serviceProvider)
    {
        _paymentHandler = paymentHandler;
    }

    // Najam se može završiti tek kad je vozilo preuzeto; vraćanje prije dogovorenog kraja je dozvoljeno.
    public override Task CompleteAsync(Reservation reservation)
    {
        if (DateTime.UtcNow < reservation.PickupAt)
        {
            throw new ClientException("Rezervacija se može završiti tek nakon preuzimanja vozila.");
        }

        return ChangeStatusAsync(reservation, ReservationStatus.Completed, null, ReservationNotifications.Completed);
    }

    // Prijava: administrator izuzetno otkazuje potvrđenu rezervaciju prije preuzimanja ili u toku najma
    // (npr. zbog kvara vozila), uz obavezan razlog (provjerava ReservationCancelValidator).
    // U oba slučaja korisniku se vraća uplaćeni iznos (prijava).
    public override async Task CancelAsync(Reservation reservation, string? reason)
    {
        if (!IsAdministrator)
        {
            await CancelByCustomerAsync(reservation, reason);
        }
        else
        {
            if (DateTime.UtcNow >= reservation.ReturnAt)
            {
                throw new ClientException("Period najma je istekao, pa se rezervacija ne može otkazati. Označite je kao završenu.");
            }

            await ChangeStatusAsync(reservation, ReservationStatus.Cancelled, reason,
                (r, vehicleName) => ReservationNotifications.CancelledByAdministrator(r, vehicleName, reason!));
        }

        await _paymentHandler.ReleaseAsync(reservation);
    }

    public override List<string> GetAllowedActions(ReservationResponse reservation)
    {
        if (!IsAdministrator)
        {
            return CustomerActions(reservation);
        }

        var now = DateTime.UtcNow;
        var actions = new List<string>();

        if (now >= reservation.PickupAt)
        {
            actions.Add(ReservationActions.Complete);
        }

        if (now < reservation.ReturnAt)
        {
            actions.Add(ReservationActions.Cancel);
        }

        return actions;
    }
}
