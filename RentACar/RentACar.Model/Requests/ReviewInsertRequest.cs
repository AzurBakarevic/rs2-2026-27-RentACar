namespace RentACar.Model.Requests;

// Recenzija se ostavlja za završenu rezervaciju (prijava), a vozilo i korisnik se uzimaju iz nje.
public class ReviewInsertRequest
{
    public int ReservationId { get; set; }

    // Ocjena od 1 do 5.
    public int Rating { get; set; }

    public string? Comment { get; set; }
}
