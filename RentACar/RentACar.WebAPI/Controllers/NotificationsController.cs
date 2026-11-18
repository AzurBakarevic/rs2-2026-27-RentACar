using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Notifikacije prijavljenog korisnika; mobilna aplikacija ih osvježava pollingom (prijava).
public class NotificationsController : BaseReadController<NotificationResponse, NotificationSearchObject, INotificationService>
{
    public NotificationsController(INotificationService notificationService) : base(notificationService)
    {
    }

    [HttpGet("UnreadCount")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<int> GetUnreadCount()
    {
        return await _service.GetUnreadCountAsync();
    }

    [HttpPut("{id:int}/Read")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        await _service.MarkAsReadAsync(id);
        return NoContent();
    }

    [HttpPut("ReadAll")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> MarkAllAsRead()
    {
        await _service.MarkAllAsReadAsync();
        return NoContent();
    }
}
