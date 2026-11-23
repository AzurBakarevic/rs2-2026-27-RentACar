namespace RentACar.Services.Interfaces;

public interface IReservationJobService
{
    Task<int> ExpireUnpaidReservationsAsync(CancellationToken cancellationToken);

    Task<int> SendPickupRemindersAsync(CancellationToken cancellationToken);
}
