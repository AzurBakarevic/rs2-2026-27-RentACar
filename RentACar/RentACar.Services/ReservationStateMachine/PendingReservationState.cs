using Microsoft.EntityFrameworkCore;
using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Exceptions;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

// Na čekanju: administrator potvrđuje (samo plaćenu) ili odbija rezervaciju, a korisnik je može otkazati.
public class PendingReservationState : BaseReservationState
{
    public PendingReservationState(RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser, IServiceProvider serviceProvider)
        : base(dbContext, authenticatedUser, serviceProvider)
    {
    }

    // Prijava: potvrditi se može samo plaćena rezervacija.
    public override async Task ConfirmAsync(Reservation reservation)
    {
        if (!await DbContext.Payments.AnyAsync(x => x.ReservationId == reservation.Id && x.Status == PaymentStatus.Paid))
        {
            throw new ClientException("Potvrditi se može samo plaćena rezervacija.");
        }

        await ChangeStatusAsync(reservation, ReservationStatus.Confirmed, null, ReservationNotifications.Confirmed);
    }

    // Prijava: odbijena rezervacija prelazi u status Otkazana, uz obavezan razlog.
    public override Task RejectAsync(Reservation reservation, string reason)
        => ChangeStatusAsync(reservation, ReservationStatus.Cancelled, reason,
            (r, vehicleName) => ReservationNotifications.Rejected(r, vehicleName, reason));

    public override Task CancelAsync(Reservation reservation, string? reason)
    {
        // Prijava: rezervaciju na čekanju administrator potvrđuje ili odbija; otkazati može samo potvrđenu.
        if (IsAdministrator)
        {
            throw new ClientException("Rezervaciju na čekanju odbijte umjesto otkazivanja.");
        }

        return CancelByCustomerAsync(reservation, reason);
    }

    public override List<string> GetAllowedActions(ReservationResponse reservation)
    {
        if (!IsAdministrator)
        {
            return CustomerActions(reservation);
        }

        return reservation.IsPaid
            ? [ReservationActions.Confirm, ReservationActions.Reject]
            : [ReservationActions.Reject];
    }
}
