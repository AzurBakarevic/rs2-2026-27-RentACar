using System.Globalization;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using RentACar.Services.Helpers;

namespace RentACar.Services.Reports;

internal static class ReportLayout
{
    private const string AccentColor = "#4F46A5";

    private static readonly NumberFormatInfo AmountFormat = new() { NumberDecimalSeparator = ",", NumberGroupSeparator = "." };

    public static byte[] Generate(string title, DateOnly from, DateOnly to, bool landscape, Action<ColumnDescriptor> composeContent)
    {
        var createdAt = AgencyTime.Format(DateTime.UtcNow);

        return Document.Create(document => document.Page(page =>
            {
                page.Size(landscape ? PageSizes.A4.Landscape() : PageSizes.A4);
                page.Margin(1.5f, Unit.Centimetre);
                page.DefaultTextStyle(x => x.FontSize(9));

                page.Header().Column(column =>
                {
                    column.Item().Row(row =>
                    {
                        row.RelativeItem().Text("RentACar").FontSize(16).Bold().FontColor(AccentColor);
                        row.RelativeItem().AlignRight().AlignBottom()
                            .Text($"Kreirano: {createdAt}").FontSize(8).FontColor(Colors.Grey.Darken1);
                    });
                    column.Item().PaddingTop(8).Text(title).FontSize(13).SemiBold();
                    column.Item().Text($"Period: {AgencyTime.FormatDate(from)} – {AgencyTime.FormatDate(to)}");
                    column.Item().PaddingTop(8).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);
                });

                page.Content().PaddingVertical(12).Column(composeContent);

                page.Footer().AlignCenter().Text(text =>
                {
                    text.DefaultTextStyle(x => x.FontSize(8).FontColor(Colors.Grey.Darken1));
                    text.Span("Stranica ");
                    text.CurrentPageNumber();
                    text.Span(" od ");
                    text.TotalPages();
                });
            }))
            .WithMetadata(new DocumentMetadata { Title = title, Author = "RentACar", Creator = "RentACar" })
            .GeneratePdf();
    }

    public static IContainer HeaderCell(IContainer container) => container
        .Background(Colors.Grey.Lighten3)
        .PaddingVertical(5)
        .PaddingHorizontal(4)
        .DefaultTextStyle(x => x.SemiBold());

    public static IContainer BodyCell(IContainer container) => container
        .BorderBottom(0.5f)
        .BorderColor(Colors.Grey.Lighten2)
        .PaddingVertical(4)
        .PaddingHorizontal(4);

    public static void EmptyMessage(ColumnDescriptor column, string message)
        => column.Item().PaddingVertical(20).AlignCenter().Text(message).FontColor(Colors.Grey.Darken1);

    public static void Summary(ColumnDescriptor column, IEnumerable<(string Label, string Value)> lines, string note)
    {
        column.Item().PaddingTop(12).AlignRight().Column(summary =>
        {
            foreach (var (label, value) in lines)
            {
                summary.Item().Text(text =>
                {
                    text.Span($"{label}: ");
                    text.Span(value).SemiBold();
                });
            }
        });

        column.Item().PaddingTop(8).Text(note).FontSize(8).FontColor(Colors.Grey.Darken1);
    }

    public static string Amount(decimal amount) => amount.ToString("#,##0.00", AmountFormat);

    public static string Days(int days) => days % 10 == 1 && days % 100 != 11 ? $"{days} dan" : $"{days} dana";
}
