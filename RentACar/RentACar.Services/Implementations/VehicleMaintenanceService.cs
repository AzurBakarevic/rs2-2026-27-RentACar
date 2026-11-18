using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Exceptions;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class VehicleMaintenanceService
    : BaseCRUDService<VehicleMaintenance, VehicleMaintenanceResponse, VehicleMaintenanceSearchObject,
        VehicleMaintenanceInsertRequest, VehicleMaintenanceUpdateRequest>,
      IVehicleMaintenanceService
{
    public VehicleMaintenanceService(
        RentACarDbContext dbContext,
        IMapper mapper,
        IValidator<VehicleMaintenanceInsertRequest> insertValidator,
        IValidator<VehicleMaintenanceUpdateRequest> updateValidator) : base(dbContext, mapper, insertValidator, updateValidator)
    {
    }

    protected override IQueryable<VehicleMaintenance> ApplyFilters(IQueryable<VehicleMaintenance> query, VehicleMaintenanceSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Text))
        {
            var text = search.Text.Trim();
            query = query.Where(x => x.Vehicle.RegistrationNumber.Contains(text)
                                     || (x.Vehicle.VehicleModel.Brand.Name + " " + x.Vehicle.VehicleModel.Name).Contains(text));
        }

        if (search.VehicleId.HasValue)
        {
            query = query.Where(x => x.VehicleId == search.VehicleId.Value);
        }

        // Servis koji bar dijelom pada u traženi period: završava poslije njegovog početka i počinje prije njegovog kraja.
        if (search.From.HasValue)
        {
            query = query.Where(x => x.EndAt > search.From.Value);
        }

        if (search.To.HasValue)
        {
            query = query.Where(x => x.StartAt < search.To.Value);
        }

        return query;
    }

    // Najnoviji servisi prvi.
    protected override IQueryable<VehicleMaintenance> ApplyOrdering(IQueryable<VehicleMaintenance> query)
        => query.OrderByDescending(x => x.StartAt).ThenByDescending(x => x.Id);

    protected override Task BeforeInsertAsync(VehicleMaintenanceInsertRequest request, VehicleMaintenance entity) => ValidateAsync(entity);

    protected override Task BeforeUpdateAsync(VehicleMaintenanceUpdateRequest request, VehicleMaintenance entity) => ValidateAsync(entity);

    private async Task ValidateAsync(VehicleMaintenance entity)
    {
        entity.Description = entity.Description.Trim();

        if (!await _dbContext.Vehicles.AnyAsync(x => x.Id == entity.VehicleId))
        {
            throw new ClientException("Odabrano vozilo ne postoji.");
        }

        // Prijava: sistem ne dozvoljava servis koji se preklapa s postojećom (aktivnom) rezervacijom tog vozila.
        if (await _dbContext.Reservations.AnyAsync(x => x.VehicleId == entity.VehicleId
                                                       && ReservationStatuses.Active.Contains(x.Status)
                                                       && x.PickupAt < entity.EndAt
                                                       && entity.StartAt < x.ReturnAt))
        {
            throw new ClientException("Vozilo u ovom periodu ima rezervaciju, pa se servis ne može unijeti.");
        }

        if (await _dbContext.VehicleMaintenances.AnyAsync(x => x.VehicleId == entity.VehicleId
                                                              && x.Id != entity.Id
                                                              && x.StartAt < entity.EndAt
                                                              && entity.StartAt < x.EndAt))
        {
            throw new ClientException("Za ovo vozilo već postoji servis u ovom periodu.");
        }
    }
}
