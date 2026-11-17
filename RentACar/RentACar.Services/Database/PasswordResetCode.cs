namespace RentACar.Services.Database;

public class PasswordResetCode
{
    public int Id { get; set; }
    public string CodeHash { get; set; } = null!;
    public DateTime ExpiresAt { get; set; }
    public DateTime? UsedAt { get; set; }
    public DateTime CreatedAt { get; set; }

    public int UserId { get; set; }
    public User User { get; set; } = null!;
}
