using RentACar.Model.Enums;

namespace RentACar.Services.Helpers;

public static class ReservationStatuses
{
    // Rezervacije koje zauzimaju vozilo: na čekanju (čeka plaćanje ili potvrdu) i potvrđene.
    // Završene i otkazane više ne smetaju novim rezervacijama ni servisima.
    public static readonly ReservationStatus[] Active = [ReservationStatus.Pending, ReservationStatus.Confirmed];
}
