using FluentValidation;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Enums;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;
using RentACar.Services.Reports;

namespace RentACar.Services.Implementations;

public class ReportService : IReportService
{
    private const string PdfContentType = "application/pdf";

    private readonly RentACarDbContext _dbContext;
    private readonly IValidator<ReportPeriodRequest> _periodValidator;

    public ReportService(RentACarDbContext dbContext, IValidator<ReportPeriodRequest> periodValidator)
    {
        _dbContext = dbContext;
        _periodValidator = periodValidator;
    }

    public async Task<FileResponse> GetReservationReportAsync(ReportPeriodRequest request)
    {
        var (from, to) = await ValidatePeriodAsync(request);
        var (fromUtc, toUtc) = ToUtcRange(from, to);

        var rows = await _dbContext.Reservations
            .AsNoTracking()
            .Where(x => x.PickupAt >= fromUtc && x.PickupAt < toUtc)
            .OrderBy(x => x.PickupAt)
            .ThenBy(x => x.Id)
            .Select(x => new ReservationReportRow
            {
                UserFullName = x.User.FirstName + " " + x.User.LastName,
                VehicleName = x.Vehicle.VehicleModel.Brand.Name + " " + x.Vehicle.VehicleModel.Name,
                RegistrationNumber = x.Vehicle.RegistrationNumber,
                PickupAt = x.PickupAt,
                ReturnAt = x.ReturnAt,
                RentalDays = x.RentalDays,
                Status = x.Status,
                TotalPrice = x.TotalPrice,
                PaidAmount = x.Payments
                    .Where(p => p.Status == PaymentStatus.Paid)
                    .Sum(p => p.ChargedAmount ?? p.Amount)
            })
            .ToListAsync();

        return new FileResponse
        {
            Content = ReservationReport.Generate(from, to, rows),
            ContentType = PdfContentType,
            FileName = $"rezervacije-i-prihod_{from:yyyy-MM-dd}_{to:yyyy-MM-dd}.pdf"
        };
    }

    public async Task<FileResponse> GetMostRentedVehiclesReportAsync(ReportPeriodRequest request)
    {
        var (from, to) = await ValidatePeriodAsync(request);
        var (fromUtc, toUtc) = ToUtcRange(from, to);

        var rows = await _dbContext.Payments
            .AsNoTracking()
            .Where(x => x.Status == PaymentStatus.Paid
                        && x.Reservation.PickupAt >= fromUtc
                        && x.Reservation.PickupAt < toUtc)
            .GroupBy(x => new
            {
                x.Reservation.VehicleId,
                BrandName = x.Reservation.Vehicle.VehicleModel.Brand.Name,
                ModelName = x.Reservation.Vehicle.VehicleModel.Name,
                x.Reservation.Vehicle.RegistrationNumber,
                CategoryName = x.Reservation.Vehicle.Category.Name
            })
            .Select(g => new MostRentedVehicleRow
            {
                VehicleName = g.Key.BrandName + " " + g.Key.ModelName,
                RegistrationNumber = g.Key.RegistrationNumber,
                CategoryName = g.Key.CategoryName,
                ReservationCount = g.Count(),
                Revenue = g.Sum(x => x.ChargedAmount ?? x.Amount)
            })
            .OrderByDescending(x => x.ReservationCount)
            .ThenByDescending(x => x.Revenue)
            .ThenBy(x => x.VehicleName)
            .ThenBy(x => x.RegistrationNumber)
            .ToListAsync();

        return new FileResponse
        {
            Content = MostRentedVehiclesReport.Generate(from, to, rows),
            ContentType = PdfContentType,
            FileName = $"najcesce-iznajmljivana-vozila_{from:yyyy-MM-dd}_{to:yyyy-MM-dd}.pdf"
        };
    }

    private async Task<(DateOnly From, DateOnly To)> ValidatePeriodAsync(ReportPeriodRequest request)
    {
        await _periodValidator.ValidateAndThrowAsync(request);
        return (request.From!.Value, request.To!.Value);
    }

    private static (DateTime From, DateTime To) ToUtcRange(DateOnly from, DateOnly to)
        => (AgencyTime.StartOfDayUtc(from), AgencyTime.StartOfDayUtc(to.AddDays(1)));
}
