using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Exceptions;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

// Potvrđena: administrator je nakon vraćanja vozila označava kao završenu ili je izuzetno otkazuje,
// a korisnik je može otkazati najkasnije 24 sata prije preuzimanja.
public class ConfirmedReservationState : BaseReservationState
{
    public ConfirmedReservationState(RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser, IServiceProvider serviceProvider)
        : base(dbContext, authenticatedUser, serviceProvider)
    {
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
    public override Task CancelAsync(Reservation reservation, string? reason)
    {
        if (!IsAdministrator)
        {
            return CancelByCustomerAsync(reservation, reason);
        }

        if (DateTime.UtcNow >= reservation.ReturnAt)
        {
            throw new ClientException("Period najma je istekao, pa se rezervacija ne može otkazati. Označite je kao završenu.");
        }

        return ChangeStatusAsync(reservation, ReservationStatus.Cancelled, reason,
            (r, vehicleName) => ReservationNotifications.CancelledByAdministrator(r, vehicleName, reason!));
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
