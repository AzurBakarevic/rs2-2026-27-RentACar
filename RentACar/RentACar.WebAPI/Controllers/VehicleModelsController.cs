using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Čitaju svi prijavljeni (npr. filteri u mobilnoj aplikaciji), a mijenja samo administrator.
public class VehicleModelsController
    : BaseCRUDController<VehicleModelResponse, VehicleModelSearchObject, VehicleModelInsertRequest, VehicleModelUpdateRequest, IVehicleModelService>
{
    public VehicleModelsController(IVehicleModelService vehicleModelService) : base(vehicleModelService)
    {
    }

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<VehicleModelResponse>> Create([FromBody] VehicleModelInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<VehicleModelResponse>> Update(int id, [FromBody] VehicleModelUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
