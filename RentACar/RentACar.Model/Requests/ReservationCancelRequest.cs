namespace RentACar.Model.Requests;

// Razlog je obavezan kad rezervaciju otkazuje administrator (prijava), a korisnik ga može izostaviti.
public class ReservationCancelRequest
{
    public string? Reason { get; set; }
}
