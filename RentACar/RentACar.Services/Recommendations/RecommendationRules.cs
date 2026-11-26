using RentACar.Model.Enums;

namespace RentACar.Services.Recommendations;

public static class RecommendationRules
{
    public const int RecommendationCount = 5;

    public static readonly ReservationStatus[] RentalStatuses = [ReservationStatus.Confirmed, ReservationStatus.Completed];
}
