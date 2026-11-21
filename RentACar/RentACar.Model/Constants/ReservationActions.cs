namespace RentACar.Model.Constants;

// Nazivi akcija u AllowedActions odgovora rezervacije. Aplikacije po njima prikazuju dugmad
// (desktop: Potvrdi, Odbij, Završi, Otkaži; mobilna: Plati, Otkaži, Recenzija), a pravila provjerava server.
public static class ReservationActions
{
    public const string Confirm = "Confirm";
    public const string Reject = "Reject";
    public const string Complete = "Complete";
    public const string Cancel = "Cancel";
    public const string Pay = "Pay";
    public const string Review = "Review";
}
