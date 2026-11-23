using RentACar.Services.Database;

namespace RentACar.Services.Helpers;

public static class ReservationRules
{
    public const int MaxRentalDays = 30;

    public const int CustomerCancellationNoticeHours = 24;

    public const int PickupReminderHours = 24;

    public static int GetRentalDays(DateTime pickupAt, DateTime returnAt)
    {
        var ticks = (returnAt - pickupAt).Ticks;
        return (int)((ticks + TimeSpan.TicksPerDay - 1) / TimeSpan.TicksPerDay);
    }

    public static decimal GetSeasonalSurcharge(DateTime pickupAt, int rentalDays, decimal pricePerDay,
        IReadOnlyCollection<SeasonalPrice> seasons)
    {
        decimal surcharge = 0;

        for (var day = 0; day < rentalDays; day++)
        {
            var date = AgencyTime.ToLocalDate(pickupAt.AddDays(day));
            var season = seasons.FirstOrDefault(x => x.StartDate <= date && date <= x.EndDate);

            if (season != null)
            {
                surcharge += pricePerDay * season.IncreasePercentage / 100m;
            }
        }

        return Math.Round(surcharge, 2, MidpointRounding.AwayFromZero);
    }

    public static bool CanCustomerCancel(DateTime pickupAt, DateTime now)
        => now <= pickupAt.AddHours(-CustomerCancellationNoticeHours);
}
