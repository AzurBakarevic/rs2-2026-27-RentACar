using Microsoft.AspNetCore.Authorization;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

[Authorize(Roles = RoleNames.Administrator)]
public class VehicleMaintenancesController
    : BaseCRUDController<VehicleMaintenanceResponse, VehicleMaintenanceSearchObject, VehicleMaintenanceInsertRequest,
        VehicleMaintenanceUpdateRequest, IVehicleMaintenanceService>
{
    public VehicleMaintenancesController(IVehicleMaintenanceService vehicleMaintenanceService) : base(vehicleMaintenanceService)
    {
    }
}
