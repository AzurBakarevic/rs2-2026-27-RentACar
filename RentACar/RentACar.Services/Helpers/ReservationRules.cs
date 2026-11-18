using RentACar.Services.Database;

namespace RentACar.Services.Helpers;

// Pravila rezervacije iz prijave na jednom mjestu, da ih koriste i obračun i state machine.
public static class ReservationRules
{
    // Najduži najam; duži period se odbija već u validaciji zahtjeva.
    public const int MaxRentalDays = 30;

    // Korisnik može otkazati rezervaciju najkasnije 24 sata prije preuzimanja vozila (prijava).
    public const int CustomerCancellationNoticeHours = 24;

    // Svaki započeti period od 24 sata najma računa se kao jedan dan (prijava), npr. 24 h = 1, 25 h = 2, 48 h = 2 dana (upute 7).
    public static int GetRentalDays(DateTime pickupAt, DateTime returnAt)
    {
        var ticks = (returnAt - pickupAt).Ticks;
        return (int)((ticks + TimeSpan.TicksPerDay - 1) / TimeSpan.TicksPerDay);
    }

    // Uvećanje se obračunava samo za dane najma koji padaju u period aktivne sezonske cijene (prijava).
    // Dan najma pripada lokalnom datumu u kojem počinje njegovih 24 sata; aktivne sezone se ne preklapaju,
    // pa jednom danu odgovara najviše jedna sezona.
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
