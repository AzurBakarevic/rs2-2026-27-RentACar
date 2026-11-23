using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Exceptions;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

public class BaseReservationState
{
    protected RentACarDbContext DbContext { get; }
    protected IAuthenticatedUserAccessor AuthenticatedUser { get; }
    protected IServiceProvider ServiceProvider { get; }

    public BaseReservationState(RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser, IServiceProvider serviceProvider)
    {
        DbContext = dbContext;
        AuthenticatedUser = authenticatedUser;
        ServiceProvider = serviceProvider;
    }

    public virtual Task<Reservation> InsertAsync(ReservationInsertRequest request)
        => throw new ClientException("Rezervacija se ne može kreirati u ovom stanju.");

    public virtual Task ConfirmAsync(Reservation reservation) => throw NotAllowed(reservation);

    public virtual Task RejectAsync(Reservation reservation, string reason) => throw NotAllowed(reservation);

    public virtual Task CompleteAsync(Reservation reservation) => throw NotAllowed(reservation);

    public virtual Task CancelAsync(Reservation reservation, string? reason) => throw NotAllowed(reservation);

    public virtual Task<bool> ExpireAsync(Reservation reservation) => Task.FromResult(false);

    public virtual List<string> GetAllowedActions(ReservationResponse reservation) => [];

    public virtual Dictionary<string, string> GetActionBlockedReasons(ReservationResponse reservation) => [];

    public BaseReservationState GetReservationState(ReservationStatus? status) => status switch
    {
        null => ServiceProvider.GetRequiredService<InitialReservationState>(),
        ReservationStatus.Pending => ServiceProvider.GetRequiredService<PendingReservationState>(),
        ReservationStatus.Confirmed => ServiceProvider.GetRequiredService<ConfirmedReservationState>(),
        ReservationStatus.Completed => ServiceProvider.GetRequiredService<CompletedReservationState>(),
        ReservationStatus.Cancelled => ServiceProvider.GetRequiredService<CancelledReservationState>(),
        _ => throw new InvalidOperationException($"Unknown reservation status: {status}")
    };

    protected bool IsAdministrator => AuthenticatedUser.IsInRole(RoleNames.Administrator);

    protected async Task ChangeStatusAsync(Reservation reservation, ReservationStatus newStatus, string? reason,
        Func<Reservation, string, Notification> createNotification)
    {
        var vehicleName = await DbContext.Vehicles
            .Where(x => x.Id == reservation.VehicleId)
            .Select(x => x.VehicleModel.Brand.Name + " " + x.VehicleModel.Name)
            .FirstAsync();

        DbContext.ReservationStatusHistory.Add(new ReservationStatusHistory
        {
            ReservationId = reservation.Id,
            OldStatus = reservation.Status,
            NewStatus = newStatus,
            Reason = reason,
            ChangedAt = DateTime.UtcNow,
            ChangedByUserId = AuthenticatedUser.GetUserId()
        });

        reservation.Status = newStatus;

        var notification = createNotification(reservation, vehicleName);
        DbContext.Notifications.Add(notification);

        if (EmailMessages.IsSentFor(newStatus))
        {
            var recipient = await DbContext.Users
                .Where(x => x.Id == reservation.UserId && !x.IsDeleted)
                .Select(x => new { x.Email, x.FirstName })
                .FirstOrDefaultAsync();

            if (recipient != null)
            {
                ServiceProvider.GetRequiredService<PendingEmails>()
                    .Add(EmailMessages.ReservationStatusChanged(recipient.Email, recipient.FirstName, notification));
            }
        }
    }

    protected Task CancelByCustomerAsync(Reservation reservation, string? reason)
    {
        EnsureNotBlocked(ReservationBlockedReasons.CancelByCustomer(reservation.PickupAt, DateTime.UtcNow));

        return ChangeStatusAsync(reservation, ReservationStatus.Cancelled, reason, ReservationNotifications.CancelledByCustomer);
    }

    protected static List<string> CustomerActions(ReservationResponse reservation)
        => ReservationRules.CanCustomerCancel(reservation.PickupAt, DateTime.UtcNow) ? [ReservationActions.Cancel] : [];

    protected static Dictionary<string, string> CustomerBlockedReasons(ReservationResponse reservation)
        => BlockedOnly((ReservationActions.Cancel, ReservationBlockedReasons.CancelByCustomer(reservation.PickupAt, DateTime.UtcNow)));

    protected static Dictionary<string, string> BlockedOnly(params (string Action, string? Reason)[] actions)
        => actions.Where(x => x.Reason != null).ToDictionary(x => x.Action, x => x.Reason!);

    protected static void EnsureNotBlocked(string? blockedReason)
    {
        if (blockedReason != null)
        {
            throw new ClientException(blockedReason);
        }
    }

    private static ClientException NotAllowed(Reservation reservation)
    {
        var status = ReservationNotifications.StatusName(reservation.Status);

        return reservation.Status is ReservationStatus.Completed or ReservationStatus.Cancelled
            ? new ClientException($"Rezervacija sa statusom \"{status}\" se više ne može mijenjati.")
            : new ClientException($"Ova akcija nije dozvoljena za rezervaciju sa statusom \"{status}\".");
    }
}
