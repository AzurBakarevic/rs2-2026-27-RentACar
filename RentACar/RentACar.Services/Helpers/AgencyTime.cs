using System.Globalization;

namespace RentACar.Services.Helpers;

// Vremena se u bazi i API-ju čuvaju u UTC-u (upute A.4), a agencija radi po lokalnom vremenu u BiH.
// Lokalno vrijeme treba tamo gdje se porede kalendarski datumi (sezonske cijene, važenje vozačke dozvole)
// i gdje korisnik čita vrijeme u tekstu (notifikacije).
public static class AgencyTime
{
    private static readonly TimeZoneInfo TimeZone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Sarajevo");

    // Vrijeme bez oznake zone (Unspecified) smatra se UTC-om, isto kao pri spremanju u bazu (UtcDateTimeConverter).
    public static DateTime AsUtc(DateTime value) => value.Kind switch
    {
        DateTimeKind.Utc => value,
        DateTimeKind.Local => value.ToUniversalTime(),
        _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
    };

    public static DateTime ToLocal(DateTime utc) => TimeZoneInfo.ConvertTimeFromUtc(AsUtc(utc), TimeZone);

    public static DateOnly ToLocalDate(DateTime utc) => DateOnly.FromDateTime(ToLocal(utc));

    // Ponoć lokalnog dana u UTC-u (npr. 1.10. ljeti je 30.9. 22:00 UTC); za periode po kalendarskim danima.
    public static DateTime StartOfDayUtc(DateOnly localDate)
        => TimeZoneInfo.ConvertTimeToUtc(localDate.ToDateTime(TimeOnly.MinValue), TimeZone);

    // Npr. "12.10.2026.".
    public static string FormatDate(DateOnly date) => date.ToString("dd.MM.yyyy.", CultureInfo.InvariantCulture);

    // Npr. "12.10.2026. 09:00".
    public static string Format(DateTime utc) => ToLocal(utc).ToString("dd.MM.yyyy. HH:mm", CultureInfo.InvariantCulture);
}
