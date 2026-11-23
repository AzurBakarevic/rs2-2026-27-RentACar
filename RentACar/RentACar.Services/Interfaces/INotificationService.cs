using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

public interface INotificationService : IBaseReadService<NotificationResponse, NotificationSearchObject>
{
    Task<int> GetUnreadCountAsync();

    Task MarkAsReadAsync(int id);

    Task MarkAllAsReadAsync();
}
