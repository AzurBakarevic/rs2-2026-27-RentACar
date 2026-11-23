using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Exceptions;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

public class PendingReservationState : BaseReservationState
{
    private readonly ReservationPaymentHandler _paymentHandler;

    public PendingReservationState(RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser, IServiceProvider serviceProvider,
        ReservationPaymentHandler paymentHandler)
        : base(dbContext, authenticatedUser, serviceProvider)
    {
        _paymentHandler = paymentHandler;
    }

    public override async Task ConfirmAsync(Reservation reservation)
    {
        var payment = await _paymentHandler.SyncAsync(reservation);
        EnsureNotBlocked(ReservationBlockedReasons.Confirm(payment?.Status == PaymentStatus.Paid));

        await ChangeStatusAsync(reservation, ReservationStatus.Confirmed, null, ReservationNotifications.Confirmed);
    }

    public override async Task RejectAsync(Reservation reservation, string reason)
    {
        await ChangeStatusAsync(reservation, ReservationStatus.Cancelled, reason,
            (r, vehicleName) => ReservationNotifications.Rejected(r, vehicleName, reason));

        await _paymentHandler.ReleaseAsync(reservation);
    }

    public override async Task CancelAsync(Reservation reservation, string? reason)
    {
        if (IsAdministrator)
        {
            throw new ClientException("Rezervaciju na čekanju odbijte umjesto otkazivanja.");
        }

        await CancelByCustomerAsync(reservation, reason);
        await _paymentHandler.ReleaseAsync(reservation);
    }

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

    public override Dictionary<string, string> GetActionBlockedReasons(ReservationResponse reservation)
        => IsAdministrator
            ? BlockedOnly((ReservationActions.Confirm, ReservationBlockedReasons.Confirm(reservation.IsPaid)))
            : CustomerBlockedReasons(reservation);
}
