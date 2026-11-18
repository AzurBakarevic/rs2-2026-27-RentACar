using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

// Notifikacije prijavljenog korisnika. Upisuju ih akcije nad rezervacijama, a korisnik ih samo čita i označava kao pročitane.
public interface INotificationService : IBaseReadService<NotificationResponse, NotificationSearchObject>
{
    // Broj uz ikonu zvona (prijava: početni ekran mobilne aplikacije).
    Task<int> GetUnreadCountAsync();

    Task MarkAsReadAsync(int id);

    Task MarkAllAsReadAsync();
}
