using System.Globalization;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using RentACar.Model.Enums;
using RentACar.Services.Helpers;

namespace RentACar.Services.Reports;

internal class ReservationReportRow
{
    public string UserFullName { get; init; } = string.Empty;
    public string VehicleName { get; init; } = string.Empty;
    public string RegistrationNumber { get; init; } = string.Empty;
    public DateTime PickupAt { get; init; }
    public DateTime ReturnAt { get; init; }
    public int RentalDays { get; init; }
    public ReservationStatus Status { get; init; }
    public decimal TotalPrice { get; init; }

    // Uplaćeno i nije vraćeno; 0 za neplaćenu i otkazanu rezervaciju.
    public decimal PaidAmount { get; init; }
}

// Prijava: PDF sa svim rezervacijama u periodu (korisnik, vozilo, trajanje najma, status i iznos),
// ukupnim brojem rezervacija i ukupnim prihodom.
internal static class ReservationReport
{
    public const string Title = "Rezervacije i prihod po periodu";

    public static byte[] Generate(DateOnly from, DateOnly to, IReadOnlyList<ReservationReportRow> rows)
    {
        var totalRevenue = rows.Sum(x => x.PaidAmount);

        return ReportLayout.Generate(Title, from, to, landscape: true, column =>
        {
            if (rows.Count == 0)
            {
                ReportLayout.EmptyMessage(column, "Nema rezervacija s preuzimanjem vozila u odabranom periodu.");
            }
            else
            {
                column.Item().Table(table =>
                {
                    table.ColumnsDefinition(columns =>
                    {
                        columns.ConstantColumn(28);
                        columns.RelativeColumn(3);
                        columns.RelativeColumn(3);
                        columns.RelativeColumn(2);
                        columns.RelativeColumn(2);
                        columns.RelativeColumn(1.2f);
                        columns.RelativeColumn(1.5f);
                        columns.RelativeColumn(1.5f);
                    });

                    table.Header(header =>
                    {
                        header.Cell().Element(ReportLayout.HeaderCell).Text("Rb.");
                        header.Cell().Element(ReportLayout.HeaderCell).Text("Korisnik");
                        header.Cell().Element(ReportLayout.HeaderCell).Text("Vozilo");
                        header.Cell().Element(ReportLayout.HeaderCell).Text("Preuzimanje");
                        header.Cell().Element(ReportLayout.HeaderCell).Text("Vraćanje");
                        header.Cell().Element(ReportLayout.HeaderCell).Text("Trajanje");
                        header.Cell().Element(ReportLayout.HeaderCell).Text("Status");
                        header.Cell().Element(ReportLayout.HeaderCell).AlignRight().Text("Iznos (KM)");
                    });

                    for (var i = 0; i < rows.Count; i++)
                    {
                        var row = rows[i];

                        table.Cell().Element(ReportLayout.BodyCell).Text((i + 1).ToString(CultureInfo.InvariantCulture));
                        table.Cell().Element(ReportLayout.BodyCell).Text(row.UserFullName);
                        table.Cell().Element(ReportLayout.BodyCell).Column(vehicle =>
                        {
                            vehicle.Item().Text(row.VehicleName);
                            vehicle.Item().Text(row.RegistrationNumber).FontSize(7.5f).FontColor(Colors.Grey.Darken1);
                        });
                        table.Cell().Element(ReportLayout.BodyCell).Text(AgencyTime.Format(row.PickupAt));
                        table.Cell().Element(ReportLayout.BodyCell).Text(AgencyTime.Format(row.ReturnAt));
                        table.Cell().Element(ReportLayout.BodyCell).Text(ReportLayout.Days(row.RentalDays));
                        table.Cell().Element(ReportLayout.BodyCell).Text(ReservationNotifications.StatusName(row.Status));
                        table.Cell().Element(ReportLayout.BodyCell).AlignRight().Text(ReportLayout.Amount(row.TotalPrice));
                    }
                });
            }

            ReportLayout.Summary(column,
                [
                    ("Ukupan broj rezervacija", rows.Count.ToString(CultureInfo.InvariantCulture)),
                    ("Ukupan prihod", $"{ReportLayout.Amount(totalRevenue)} KM")
                ],
                "Obuhvaćene su sve rezervacije s preuzimanjem vozila u odabranom periodu. Prihod obuhvata uplate koje nisu " +
                "vraćene, pa otkazane i neplaćene rezervacije ne ulaze u prihod.");
        });
    }
}
