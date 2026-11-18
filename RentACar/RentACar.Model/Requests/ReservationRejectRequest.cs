namespace RentACar.Model.Requests;

// Administrator odbija rezervaciju na čekanju; razlog je obavezan i korisnik ga vidi (prijava).
public class ReservationRejectRequest
{
    public string Reason { get; set; } = string.Empty;
}
