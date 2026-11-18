using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Exceptions;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

// Centralizovana state machine rezervacije (prijava, upute 7), po obrascu iz profesorovog V3 (ProductStateMachine):
// svako stanje je klasa koja prepisuje samo akcije dozvoljene u tom stanju, a ostale akcije bacaju grešku.
// Dozvoljeni prelazi: Na čekanju → Potvrđena → Završena; Na čekanju → Otkazana (odbijanje ili otkazivanje);
// Potvrđena → Otkazana. Završena i otkazana rezervacija se više ne mijenjaju.
//
// Razlika od profesora: akcija dobija već učitanu (i zaključanu) rezervaciju umjesto Id-a, a ne sprema promjene sama.
// ReservationService otvara transakciju, poziva stanje i sprema sve odjednom (status, historiju i notifikaciju).
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

    // Akcije (ReservationActions) koje prijavljeni korisnik sada smije izvršiti; u završnim stanjima nema nijedne.
    public virtual List<string> GetAllowedActions(ReservationResponse reservation) => [];

    // null = rezervacija još ne postoji (kreiranje).
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

    // Mijenja status i dodaje zapis u historiju (ko i kada, prijava) i notifikaciju za korisnika.
    // Sve se sprema zajedno, pa ne može ostati promjena statusa bez historije ili notifikacije.
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

        DbContext.Notifications.Add(createNotification(reservation, vehicleName));
    }

    // Korisnik otkazuje svoju rezervaciju (na čekanju ili potvrđenu) najkasnije 24 sata prije preuzimanja (prijava).
    protected Task CancelByCustomerAsync(Reservation reservation, string? reason)
    {
        if (!ReservationRules.CanCustomerCancel(reservation.PickupAt, DateTime.UtcNow))
        {
            throw new ClientException(
                $"Rezervaciju je moguće otkazati najkasnije {ReservationRules.CustomerCancellationNoticeHours} sata prije preuzimanja vozila.");
        }

        return ChangeStatusAsync(reservation, ReservationStatus.Cancelled, reason, ReservationNotifications.CancelledByCustomer);
    }

    protected static List<string> CustomerActions(ReservationResponse reservation)
        => ReservationRules.CanCustomerCancel(reservation.PickupAt, DateTime.UtcNow) ? [ReservationActions.Cancel] : [];

    private static ClientException NotAllowed(Reservation reservation)
    {
        var status = ReservationNotifications.StatusName(reservation.Status);

        return reservation.Status is ReservationStatus.Completed or ReservationStatus.Cancelled
            ? new ClientException($"Rezervacija sa statusom \"{status}\" se više ne može mijenjati.")
            : new ClientException($"Ova akcija nije dozvoljena za rezervaciju sa statusom \"{status}\".");
    }
}
