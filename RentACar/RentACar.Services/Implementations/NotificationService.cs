using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class NotificationService : BaseReadService<Notification, NotificationResponse, NotificationSearchObject>, INotificationService
{
    private readonly IAuthenticatedUserAccessor _authenticatedUser;

    public NotificationService(IMapper mapper, RentACarDbContext dbContext, IAuthenticatedUserAccessor authenticatedUser)
        : base(mapper, dbContext)
    {
        _authenticatedUser = authenticatedUser;
    }

    // Svako vidi samo svoje notifikacije, i administrator; tuđa notifikacija za njega ne postoji (404).
    protected override IQueryable<Notification> GetQuery()
    {
        var userId = _authenticatedUser.GetUserId();
        return base.GetQuery().Where(x => x.UserId == userId);
    }

    protected override IQueryable<Notification> ApplyFilters(IQueryable<Notification> query, NotificationSearchObject search)
    {
        if (search.IsRead.HasValue)
        {
            query = query.Where(x => x.IsRead == search.IsRead.Value);
        }

        return query;
    }

    // Najnovije prve.
    protected override IQueryable<Notification> ApplyOrdering(IQueryable<Notification> query)
        => query.OrderByDescending(x => x.CreatedAt).ThenByDescending(x => x.Id);

    public Task<int> GetUnreadCountAsync() => GetQuery().CountAsync(x => !x.IsRead);

    // Jedan UPDATE u bazi, bez učitavanja notifikacije.
    public async Task MarkAsReadAsync(int id)
    {
        var updated = await GetQuery()
            .Where(x => x.Id == id)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.IsRead, true));

        if (updated == 0)
        {
            throw new KeyNotFoundException($"Notification with id {id} not found.");
        }
    }

    public async Task MarkAllAsReadAsync()
    {
        await GetQuery()
            .Where(x => !x.IsRead)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.IsRead, true));
    }
}
