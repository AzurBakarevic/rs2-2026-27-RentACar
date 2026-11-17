using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Čitaju svi prijavljeni (npr. filteri u mobilnoj aplikaciji), a mijenja samo administrator.
public class TransmissionTypesController
    : BaseCRUDController<TransmissionTypeResponse, TransmissionTypeSearchObject, TransmissionTypeInsertRequest, TransmissionTypeUpdateRequest, ITransmissionTypeService>
{
    public TransmissionTypesController(ITransmissionTypeService transmissionTypeService) : base(transmissionTypeService)
    {
    }

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<TransmissionTypeResponse>> Create([FromBody] TransmissionTypeInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<TransmissionTypeResponse>> Update(int id, [FromBody] TransmissionTypeUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
