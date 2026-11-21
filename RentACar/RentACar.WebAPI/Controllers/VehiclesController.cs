using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;
using RentACar.WebAPI.Extensions;

namespace RentACar.WebAPI.Controllers;

// Čitaju svi prijavljeni (korisnik vidi samo aktivna vozila), a mijenja samo administrator.
public class VehiclesController
    : BaseCRUDController<VehicleResponse, VehicleSearchObject, VehicleInsertRequest, VehicleUpdateRequest, IVehicleService>
{
    public VehiclesController(IVehicleService vehicleService) : base(vehicleService)
    {
    }

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<VehicleResponse>> Create([FromBody] VehicleInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<VehicleResponse>> Update(int id, [FromBody] VehicleUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);

    // Slika kao fajl (ne base64), pa je klijent učitava po URL-u samo kad je prikazuje (upute 8.2).
    [HttpGet("{id:int}/Image")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetImage(int id)
    {
        var image = await _service.GetImageAsync(id);
        return File(image.Content, image.ContentType);
    }

    // Slika se šalje kao multipart/form-data (polje "image"), da uz sadržaj stigne i MIME tip (upute 5).
    [Authorize(Roles = RoleNames.Administrator)]
    [HttpPut("{id:int}/Image")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(FormFileExtensions.MaxImageRequestBytes)]
    [RequestFormLimits(MultipartBodyLengthLimit = FormFileExtensions.MaxImageRequestBytes)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateImage(int id, IFormFile? image)
    {
        await _service.SetImageAsync(id, await image.ToImageUploadRequestAsync());
        return NoContent();
    }
}
