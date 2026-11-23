using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

public class ConfirmedReservationState : BaseReservationState
{
    private readonly ReservationPaymentHandler _paymentHandler;

    public ConfirmedReservationState(RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser, IServiceProvider serviceProvider,
        ReservationPaymentHandler paymentHandler)
        : base(dbContext, authenticatedUser, serviceProvider)
    {
        _paymentHandler = paymentHandler;
    }

    public override Task CompleteAsync(Reservation reservation)
    {
        EnsureNotBlocked(ReservationBlockedReasons.Complete(reservation.PickupAt, DateTime.UtcNow));

        return ChangeStatusAsync(reservation, ReservationStatus.Completed, null, ReservationNotifications.Completed);
    }

    public override async Task CancelAsync(Reservation reservation, string? reason)
    {
        if (!IsAdministrator)
        {
            await CancelByCustomerAsync(reservation, reason);
        }
        else
        {
            EnsureNotBlocked(ReservationBlockedReasons.CancelByAdministrator(reservation.ReturnAt, DateTime.UtcNow));

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

        if (ReservationBlockedReasons.Complete(reservation.PickupAt, now) == null)
        {
            actions.Add(ReservationActions.Complete);
        }

        if (ReservationBlockedReasons.CancelByAdministrator(reservation.ReturnAt, now) == null)
        {
            actions.Add(ReservationActions.Cancel);
        }

        return actions;
    }

    public override Dictionary<string, string> GetActionBlockedReasons(ReservationResponse reservation)
    {
        if (!IsAdministrator)
        {
            return CustomerBlockedReasons(reservation);
        }

        var now = DateTime.UtcNow;

        return BlockedOnly(
            (ReservationActions.Complete, ReservationBlockedReasons.Complete(reservation.PickupAt, now)),
            (ReservationActions.Cancel, ReservationBlockedReasons.CancelByAdministrator(reservation.ReturnAt, now)));
    }
}
