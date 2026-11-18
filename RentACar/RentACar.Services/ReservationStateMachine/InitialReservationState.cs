using Microsoft.EntityFrameworkCore;
using RentACar.Model.Enums;
using RentACar.Model.Requests;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Implementations;
using RentACar.Services.Interfaces;

namespace RentACar.Services.ReservationStateMachine;

// Rezervacija koja još ne postoji: jedina akcija je kreiranje, nakon čega je rezervacija na čekanju.
public class InitialReservationState : BaseReservationState
{
    private readonly ReservationCalculator _calculator;

    public InitialReservationState(
        RentACarDbContext dbContext,
        IAuthenticatedUserAccessor authenticatedUser,
        IServiceProvider serviceProvider,
        ReservationCalculator calculator) : base(dbContext, authenticatedUser, serviceProvider)
    {
        _calculator = calculator;
    }

    // Poziva se unutar transakcije koju otvara ReservationService.
    public override async Task<Reservation> InsertAsync(ReservationInsertRequest request)
    {
        var userId = AuthenticatedUser.GetUserId() ?? throw new UnauthorizedAccessException();

        await LockAsync(userId, request);

        // Provjera i obračun tek nakon zaključavanja, pa vide i rezervaciju koju je upravo upisao drugi zahtjev.
        var calculation = await _calculator.CalculateAsync(userId, request);
        var now = DateTime.UtcNow;

        var reservation = new Reservation
        {
            UserId = userId,
            VehicleId = calculation.VehicleId,
            PickupAt = AgencyTime.AsUtc(request.PickupAt),
            ReturnAt = AgencyTime.AsUtc(request.ReturnAt),
            RentalDays = calculation.RentalDays,
            VehiclePrice = calculation.VehiclePrice,
            SeasonalSurcharge = calculation.SeasonalSurcharge,
            EquipmentPrice = calculation.EquipmentPrice,
            TotalPrice = calculation.TotalPrice,
            Status = ReservationStatus.Pending,
            CreatedAt = now,
            Equipment = calculation.Equipment
                .Select(x => new ReservationEquipment
                {
                    EquipmentId = x.EquipmentId,
                    Quantity = x.Quantity,
                    PricePerDay = x.PricePerDay
                })
                .ToList()
        };

        reservation.StatusHistory.Add(new ReservationStatusHistory
        {
            OldStatus = null,
            NewStatus = ReservationStatus.Pending,
            ChangedAt = now,
            ChangedByUserId = userId
        });

        DbContext.Reservations.Add(reservation);
        DbContext.Notifications.Add(ReservationNotifications.Created(reservation, calculation.VehicleName));

        return reservation;
    }

    // Zaključava red korisnika, vozila i odabrane opreme do kraja transakcije (UPDLOCK), uvijek istim redoslijedom.
    // Dva istovremena zahtjeva za isto vozilo, istog korisnika ili istu opremu se tako izvršavaju jedan za drugim,
    // pa drugi vidi rezervaciju prvog i dobija poruku da termin nije slobodan (prijava: onemogućiti preklapanje najmova).
    // Obično čitanje tih redova (npr. lista vozila) nije blokirano.
    private async Task LockAsync(int userId, ReservationInsertRequest request)
    {
        await DbContext.Database.ExecuteSqlAsync($"SELECT Id FROM Users WITH (UPDLOCK, ROWLOCK) WHERE Id = {userId}");
        await DbContext.Database.ExecuteSqlAsync($"SELECT Id FROM Vehicles WITH (UPDLOCK, ROWLOCK) WHERE Id = {request.VehicleId}");

        foreach (var equipmentId in (request.Equipment ?? []).Select(x => x.EquipmentId).Distinct().Order())
        {
            await DbContext.Database.ExecuteSqlAsync($"SELECT Id FROM Equipment WITH (UPDLOCK, ROWLOCK) WHERE Id = {equipmentId}");
        }
    }
}
