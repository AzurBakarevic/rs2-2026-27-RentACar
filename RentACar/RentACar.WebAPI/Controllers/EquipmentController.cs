using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

public class EquipmentController
    : BaseCRUDController<EquipmentResponse, EquipmentSearchObject, EquipmentInsertRequest, EquipmentUpdateRequest, IEquipmentService>
{
    public EquipmentController(IEquipmentService equipmentService) : base(equipmentService)
    {
    }

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<EquipmentResponse>> Create([FromBody] EquipmentInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<EquipmentResponse>> Update(int id, [FromBody] EquipmentUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
