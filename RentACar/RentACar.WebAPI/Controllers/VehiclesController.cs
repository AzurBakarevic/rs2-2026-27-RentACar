using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Čitaju svi prijavljeni (korisnik vidi samo aktivna vozila), a mijenja samo administrator.
public class VehiclesController
    : BaseCRUDController<VehicleResponse, VehicleSearchObject, VehicleInsertRequest, VehicleUpdateRequest, IVehicleService>
{
    // Gornja granica veličine zahtjeva za upload; dozvoljenu veličinu slike (2 MB) provjerava validator, s jasnom porukom.
    private const long MaxImageRequestBytes = 10 * 1024 * 1024;

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
    [RequestSizeLimit(MaxImageRequestBytes)]
    [RequestFormLimits(MultipartBodyLengthLimit = MaxImageRequestBytes)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateImage(int id, IFormFile? image)
    {
        var request = new ImageUploadRequest { ContentType = image?.ContentType };

        if (image != null)
        {
            using var stream = new MemoryStream();
            await image.CopyToAsync(stream);
            request.Content = stream.ToArray();
        }

        await _service.SetImageAsync(id, request);
        return NoContent();
    }
}
