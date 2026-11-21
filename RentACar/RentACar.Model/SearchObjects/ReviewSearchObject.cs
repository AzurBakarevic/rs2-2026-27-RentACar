namespace RentACar.Model.SearchObjects;

public class ReviewSearchObject : BaseSearchObject
{
    // Ime i prezime ili korisničko ime korisnika, marka i model ili registracija vozila (prijava: pretraga po korisniku ili vozilu).
    public string? Text { get; set; }

    // Recenzije jednog vozila (mobilna aplikacija: detalji vozila).
    public int? VehicleId { get; set; }
}
