using System.Globalization;
using QuestPDF.Fluent;

namespace RentACar.Services.Reports;

internal class MostRentedVehicleRow
{
    public string VehicleName { get; init; } = string.Empty;
    public string RegistrationNumber { get; init; } = string.Empty;
    public string CategoryName { get; init; } = string.Empty;
    public int ReservationCount { get; init; }
    public decimal Revenue { get; init; }
}

internal static class MostRentedVehiclesReport
{
    public const string Title = "Najčešće iznajmljivana vozila";

    public static byte[] Generate(DateOnly from, DateOnly to, IReadOnlyList<MostRentedVehicleRow> rows)
    {
        return ReportLayout.Generate(Title, from, to, landscape: false, column =>
        {
            if (rows.Count == 0)
            {
                ReportLayout.EmptyMessage(column, "Nijedno vozilo nije iznajmljeno u odabranom periodu.");
            }
            else
            {
                column.Item().Table(table =>
                {
                    table.ColumnsDefinition(columns =>
                    {
                        columns.ConstantColumn(28);
                        columns.RelativeColumn(3);
                        columns.RelativeColumn(2);
                        columns.RelativeColumn(2);
                        columns.RelativeColumn(1.6f);
                        columns.RelativeColumn(1.6f);
                    });

                    table.Header(header =>
                    {
                        header.Cell().Element(ReportLayout.HeaderCell).Text("Rb.");
                        header.Cell().Element(ReportLayout.HeaderCell).Text("Marka i model");
                        header.Cell().Element(ReportLayout.HeaderCell).Text("Registracija");
                        header.Cell().Element(ReportLayout.HeaderCell).Text("Kategorija");
                        header.Cell().Element(ReportLayout.HeaderCell).AlignRight().Text("Broj rezervacija");
                        header.Cell().Element(ReportLayout.HeaderCell).AlignRight().Text("Prihod (KM)");
                    });

                    for (var i = 0; i < rows.Count; i++)
                    {
                        var row = rows[i];

                        table.Cell().Element(ReportLayout.BodyCell).Text((i + 1).ToString(CultureInfo.InvariantCulture));
                        table.Cell().Element(ReportLayout.BodyCell).Text(row.VehicleName);
                        table.Cell().Element(ReportLayout.BodyCell).Text(row.RegistrationNumber);
                        table.Cell().Element(ReportLayout.BodyCell).Text(row.CategoryName);
                        table.Cell().Element(ReportLayout.BodyCell).AlignRight()
                            .Text(row.ReservationCount.ToString(CultureInfo.InvariantCulture));
                        table.Cell().Element(ReportLayout.BodyCell).AlignRight().Text(ReportLayout.Amount(row.Revenue));
                    }
                });
            }

            ReportLayout.Summary(column,
                [
                    ("Ukupno rezervacija", rows.Sum(x => x.ReservationCount).ToString(CultureInfo.InvariantCulture)),
                    ("Ukupan prihod", $"{ReportLayout.Amount(rows.Sum(x => x.Revenue))} KM")
                ],
                "Broje se plaćene rezervacije (uplata nije vraćena) s preuzimanjem vozila u odabranom periodu.");
        });
    }
}
