namespace RentACar.Services.Database;

// Kod se ne čuva kao tekst, nego kao PBKDF2 hash sa saltom, kao lozinka (upute A.3).
public class PasswordResetCode
{
    public int Id { get; set; }
    public string CodeHash { get; set; } = null!;
    public string CodeSalt { get; set; } = null!;
    public int FailedAttempts { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? UsedAt { get; set; }
    public DateTime CreatedAt { get; set; }

    public int UserId { get; set; }
    public User User { get; set; } = null!;
}
