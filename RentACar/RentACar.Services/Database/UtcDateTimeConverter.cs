using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace RentACar.Services.Database;

// Sva vremena se u bazi čuvaju u UTC-u (upute A.4). Kolona datetime2 ne pamti vrstu vremena, pa bi pročitana
// vrijednost bila "Unspecified" i JSON bi je vratio bez oznake "Z". Pri upisu se lokalno vrijeme pretvara u UTC,
// a vrijeme bez oznake se smatra UTC-om; pri čitanju se vrijednost označava kao UTC.
public class UtcDateTimeConverter : ValueConverter<DateTime, DateTime>
{
    public UtcDateTimeConverter()
        : base(
            value => value.Kind == DateTimeKind.Local ? value.ToUniversalTime() : DateTime.SpecifyKind(value, DateTimeKind.Utc),
            value => DateTime.SpecifyKind(value, DateTimeKind.Utc))
    {
    }
}
