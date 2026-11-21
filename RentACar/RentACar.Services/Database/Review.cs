namespace RentACar.Services.Database;

public class Review : IEntity
{
    public int Id { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }

    public int ReservationId { get; set; }
    public Reservation Reservation { get; set; } = null!;
}
