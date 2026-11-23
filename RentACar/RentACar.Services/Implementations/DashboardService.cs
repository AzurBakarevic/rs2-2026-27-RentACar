using Microsoft.EntityFrameworkCore;
using RentACar.Model.Constants;
using RentACar.Model.Enums;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class DashboardService : IDashboardService
{
    private const int ChartDays = 7;

    private readonly RentACarDbContext _dbContext;

    public DashboardService(RentACarDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<DashboardResponse> GetAsync()
    {
        return new DashboardResponse
        {
            VehicleCount = await _dbContext.Vehicles.CountAsync(),
            CustomerCount = await _dbContext.Users.CountAsync(x => !x.IsDeleted && x.Role.Name == RoleNames.Customer),
            ActiveReservationCount = await _dbContext.Reservations.CountAsync(x => ReservationStatuses.Active.Contains(x.Status)),
            AwaitingConfirmationCount = await _dbContext.Reservations.CountAsync(x =>
                x.Status == ReservationStatus.Pending && x.Payments.Any(p => p.Status == PaymentStatus.Paid)),
            ReservationsPerDay = await GetReservationsPerDayAsync()
        };
    }

    private async Task<List<DailyReservationCountResponse>> GetReservationsPerDayAsync()
    {
        var today = AgencyTime.ToLocalDate(DateTime.UtcNow);
        var firstDay = today.AddDays(-(ChartDays - 1));
        var from = AgencyTime.StartOfDayUtc(firstDay);
        var to = AgencyTime.StartOfDayUtc(today.AddDays(1));

        var countsPerHour = await _dbContext.Reservations
            .Where(x => x.CreatedAt >= from && x.CreatedAt < to)
            .GroupBy(x => EF.Functions.DateDiffHour(from, x.CreatedAt))
            .Select(g => new { Hour = g.Key, Count = g.Count() })
            .ToListAsync();

        var countsPerDay = countsPerHour
            .GroupBy(x => AgencyTime.ToLocalDate(from.AddHours(x.Hour)))
            .ToDictionary(g => g.Key, g => g.Sum(x => x.Count));

        return Enumerable.Range(0, ChartDays)
            .Select(i => firstDay.AddDays(i))
            .Select(day => new DailyReservationCountResponse { Date = day, Count = countsPerDay.GetValueOrDefault(day) })
            .ToList();
    }
}
