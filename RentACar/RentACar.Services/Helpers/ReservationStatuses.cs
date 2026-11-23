using RentACar.Model.Enums;

namespace RentACar.Services.Helpers;

public static class ReservationStatuses
{
    public static readonly ReservationStatus[] Active = [ReservationStatus.Pending, ReservationStatus.Confirmed];
}
