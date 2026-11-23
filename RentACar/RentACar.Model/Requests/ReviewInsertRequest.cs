namespace RentACar.Model.Requests;

public class ReviewInsertRequest
{
    public int ReservationId { get; set; }

    public int Rating { get; set; }

    public string? Comment { get; set; }
}
