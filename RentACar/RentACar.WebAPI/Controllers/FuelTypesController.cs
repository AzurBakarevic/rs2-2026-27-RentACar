using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Čitaju svi prijavljeni (npr. filteri u mobilnoj aplikaciji), a mijenja samo administrator.
public class FuelTypesController
    : BaseCRUDController<FuelTypeResponse, FuelTypeSearchObject, FuelTypeInsertRequest, FuelTypeUpdateRequest, IFuelTypeService>
{
    public FuelTypesController(IFuelTypeService fuelTypeService) : base(fuelTypeService)
    {
    }

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<FuelTypeResponse>> Create([FromBody] FuelTypeInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<FuelTypeResponse>> Update(int id, [FromBody] FuelTypeUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
