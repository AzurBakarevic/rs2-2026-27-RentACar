namespace RentACar.Services.Interfaces;

// Poslovi koje pozadinski servis API-ja izvršava svake minute (upute 8.2: pozadinski poslovi kroz BackgroundService).
public interface IReservationJobService
{
    // Otkazuje rezervacije koje nisu plaćene u roku od 15 minuta (prijava). Vraća broj otkazanih.
    Task<int> ExpireUnpaidReservationsAsync(CancellationToken cancellationToken);

    // Šalje podsjetnik dan prije preuzimanja vozila za potvrđene rezervacije (prijava). Vraća broj poslanih.
    Task<int> SendPickupRemindersAsync(CancellationToken cancellationToken);
}
