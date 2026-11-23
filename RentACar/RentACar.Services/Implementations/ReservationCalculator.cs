using Microsoft.EntityFrameworkCore;
using RentACar.Model.Exceptions;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Services.Database;
using RentACar.Services.Helpers;

namespace RentACar.Services.Implementations;

public class ReservationCalculator
{
    private readonly RentACarDbContext _dbContext;

    public ReservationCalculator(RentACarDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<ReservationCalculationResponse> CalculateAsync(int userId, ReservationInsertRequest request)
    {
        var pickupAt = AgencyTime.AsUtc(request.PickupAt);
        var returnAt = AgencyTime.AsUtc(request.ReturnAt);

        var vehicle = await _dbContext.Vehicles
            .AsNoTracking()
            .Where(x => x.Id == request.VehicleId && x.IsActive)
            .Select(x => new { x.Id, x.PricePerDay, Name = x.VehicleModel.Brand.Name + " " + x.VehicleModel.Name })
            .FirstOrDefaultAsync()
            ?? throw new ClientException("Odabrano vozilo nije dostupno.");

        await EnsureDriverLicenseIsValidAsync(userId, returnAt);

        if (await _dbContext.Reservations.AnyAsync(x => x.VehicleId == vehicle.Id
                                                       && ReservationStatuses.Active.Contains(x.Status)
                                                       && x.PickupAt < returnAt
                                                       && pickupAt < x.ReturnAt))
        {
            throw new ClientException("Vozilo je u odabranom periodu već rezervisano.");
        }

        if (await _dbContext.VehicleMaintenances.AnyAsync(x => x.VehicleId == vehicle.Id
                                                              && x.StartAt < returnAt
                                                              && pickupAt < x.EndAt))
        {
            throw new ClientException("Vozilo je u odabranom periodu na servisu.");
        }

        if (await _dbContext.Reservations.AnyAsync(x => x.UserId == userId
                                                       && ReservationStatuses.Active.Contains(x.Status)
                                                       && x.PickupAt < returnAt
                                                       && pickupAt < x.ReturnAt))
        {
            throw new ClientException("Već imate drugu rezervaciju u odabranom periodu.");
        }

        var rentalDays = ReservationRules.GetRentalDays(pickupAt, returnAt);
        var vehiclePrice = vehicle.PricePerDay * rentalDays;
        var seasonalSurcharge = ReservationRules.GetSeasonalSurcharge(
            pickupAt, rentalDays, vehicle.PricePerDay, await GetSeasonsAsync(pickupAt, rentalDays));
        var equipment = await CalculateEquipmentAsync(request.Equipment ?? [], pickupAt, returnAt, rentalDays);
        var equipmentPrice = equipment.Sum(x => x.TotalPrice);

        return new ReservationCalculationResponse
        {
            VehicleId = vehicle.Id,
            VehicleName = vehicle.Name,
            RentalDays = rentalDays,
            VehiclePricePerDay = vehicle.PricePerDay,
            VehiclePrice = vehiclePrice,
            SeasonalSurcharge = seasonalSurcharge,
            EquipmentPrice = equipmentPrice,
            TotalPrice = vehiclePrice + seasonalSurcharge + equipmentPrice,
            Equipment = equipment
        };
    }

    private async Task EnsureDriverLicenseIsValidAsync(int userId, DateTime returnAt)
    {
        var license = await _dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => new { x.DriverLicenseNumber, x.DriverLicenseValidUntil })
            .FirstOrDefaultAsync()
            ?? throw new UnauthorizedAccessException();

        if (string.IsNullOrWhiteSpace(license.DriverLicenseNumber) || license.DriverLicenseValidUntil == null)
        {
            throw new ClientException("Prije rezervacije unesite podatke o vozačkoj dozvoli u profilu.");
        }

        if (license.DriverLicenseValidUntil < AgencyTime.ToLocalDate(returnAt))
        {
            throw new ClientException("Vozačka dozvola ističe prije kraja najma.");
        }
    }

    private async Task<List<SeasonalPrice>> GetSeasonsAsync(DateTime pickupAt, int rentalDays)
    {
        var firstDate = AgencyTime.ToLocalDate(pickupAt);
        var lastDate = AgencyTime.ToLocalDate(pickupAt.AddDays(rentalDays - 1));

        return await _dbContext.SeasonalPrices
            .AsNoTracking()
            .Where(x => x.IsActive && x.StartDate <= lastDate && firstDate <= x.EndDate)
            .ToListAsync();
    }

    private async Task<List<ReservationEquipmentResponse>> CalculateEquipmentAsync(
        List<ReservationEquipmentRequest> requested, DateTime pickupAt, DateTime returnAt, int rentalDays)
    {
        var items = requested
            .GroupBy(x => x.EquipmentId)
            .Select(g => new { EquipmentId = g.Key, Quantity = g.Sum(x => x.Quantity) })
            .ToList();

        if (items.Count == 0)
        {
            return [];
        }

        var ids = items.Select(x => x.EquipmentId).ToList();

        var equipment = await _dbContext.Equipment
            .AsNoTracking()
            .Where(x => ids.Contains(x.Id) && x.IsActive)
            .ToListAsync();

        var bookings = await _dbContext.ReservationEquipment
            .AsNoTracking()
            .Where(x => ids.Contains(x.EquipmentId)
                        && ReservationStatuses.Active.Contains(x.Reservation.Status)
                        && x.Reservation.PickupAt < returnAt
                        && pickupAt < x.Reservation.ReturnAt)
            .Select(x => new EquipmentBooking(x.EquipmentId, x.Quantity, x.Reservation.PickupAt, x.Reservation.ReturnAt))
            .ToListAsync();

        var result = new List<ReservationEquipmentResponse>();

        foreach (var item in items)
        {
            var piece = equipment.FirstOrDefault(x => x.Id == item.EquipmentId)
                ?? throw new ClientException("Odabrana dodatna oprema nije dostupna.");

            var available = piece.Quantity - GetPeakBookedQuantity(bookings.Where(x => x.EquipmentId == piece.Id).ToList(), pickupAt, returnAt);

            if (item.Quantity > available)
            {
                throw new ClientException(available > 0
                    ? $"Oprema \"{piece.Name}\" je u odabranom periodu dostupna u količini od najviše {available}."
                    : $"Oprema \"{piece.Name}\" u odabranom periodu nije dostupna.");
            }

            result.Add(new ReservationEquipmentResponse
            {
                EquipmentId = piece.Id,
                EquipmentName = piece.Name,
                Quantity = item.Quantity,
                PricePerDay = piece.PricePerDay,
                TotalPrice = item.Quantity * piece.PricePerDay * rentalDays
            });
        }

        return result.OrderBy(x => x.EquipmentName).ToList();
    }

    private static int GetPeakBookedQuantity(List<EquipmentBooking> bookings, DateTime from, DateTime to)
    {
        return bookings
            .Select(x => x.PickupAt)
            .Where(x => x > from && x < to)
            .Append(from)
            .Max(moment => bookings.Where(x => x.PickupAt <= moment && moment < x.ReturnAt).Sum(x => x.Quantity));
    }

    private record EquipmentBooking(int EquipmentId, int Quantity, DateTime PickupAt, DateTime ReturnAt);
}
