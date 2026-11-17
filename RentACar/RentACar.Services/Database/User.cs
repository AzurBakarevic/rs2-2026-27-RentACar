namespace RentACar.Services.Database;

public class User : IEntity
{
    public int Id { get; set; }
    public string FirstName { get; set; } = null!;
    public string LastName { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string PhoneNumber { get; set; } = null!;
    public string Username { get; set; } = null!;
    public string PasswordHash { get; set; } = null!;
    public string PasswordSalt { get; set; } = null!;
    public byte[]? ProfileImage { get; set; }
    public string? DriverLicenseNumber { get; set; }
    public DateOnly? DriverLicenseValidUntil { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; }
    public DateTime CreatedAt { get; set; }

    // Povećava se pri odjavi, promjeni lozinke, uloge ili statusa; token sa starom verzijom više ne važi (upute 5).
    public int TokenVersion { get; set; }

    public int RoleId { get; set; }
    public Role Role { get; set; } = null!;

    public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
}
