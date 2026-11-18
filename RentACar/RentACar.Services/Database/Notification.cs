namespace RentACar.Services.Database;

public class Notification : IEntity
{
    public int Id { get; set; }
    public string Title { get; set; } = null!;
    public string Message { get; set; } = null!;
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }

    public int UserId { get; set; }
    public User User { get; set; } = null!;
}
