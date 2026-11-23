using System.Globalization;

namespace RentACar.Services.Helpers;

public static class AgencyTime
{
    private static readonly TimeZoneInfo TimeZone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Sarajevo");

    public static DateTime AsUtc(DateTime value) => value.Kind switch
    {
        DateTimeKind.Utc => value,
        DateTimeKind.Local => value.ToUniversalTime(),
        _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
    };

    public static DateTime ToLocal(DateTime utc) => TimeZoneInfo.ConvertTimeFromUtc(AsUtc(utc), TimeZone);

    public static DateOnly ToLocalDate(DateTime utc) => DateOnly.FromDateTime(ToLocal(utc));

    public static DateTime StartOfDayUtc(DateOnly localDate)
        => TimeZoneInfo.ConvertTimeToUtc(localDate.ToDateTime(TimeOnly.MinValue), TimeZone);

    public static string FormatDate(DateOnly date) => date.ToString("dd.MM.yyyy.", CultureInfo.InvariantCulture);

    public static string Format(DateTime utc) => ToLocal(utc).ToString("dd.MM.yyyy. HH:mm", CultureInfo.InvariantCulture);
}
