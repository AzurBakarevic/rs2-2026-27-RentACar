using RentACar.Model.Enums;

namespace RentACar.Model.SearchObjects;

public class ReservationSearchObject : BaseSearchObject
{
    // Ime i prezime ili korisničko ime korisnika, marka i model ili registracija vozila.
    public string? Text { get; set; }

    public int? UserId { get; set; }
    public int? VehicleId { get; set; }
    public ReservationStatus? Status { get; set; }

    // true = aktivne (na čekanju i potvrđene), false = prošle (završene i otkazane).
    public bool? IsActive { get; set; }

    // Rezervacije čiji period najma bar dijelom pada između From i To; za jedan dan klijent šalje početak i kraj tog dana.
    public DateTime? From { get; set; }
    public DateTime? To { get; set; }
}
