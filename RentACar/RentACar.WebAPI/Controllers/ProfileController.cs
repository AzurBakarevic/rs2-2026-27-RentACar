using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Services.Interfaces;
using RentACar.WebAPI.Extensions;

namespace RentACar.WebAPI.Controllers;

// Profil prijavljenog korisnika. Nema Id-a u ruti ni u body-ju: korisnik se uzima iz tokena (upute 5).
[Authorize]
[ApiController]
[Route("[controller]")]
public class ProfileController : ControllerBase
{
    private readonly IUserService _userService;

    public ProfileController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    public async Task<UserResponse> Get()
    {
        return await _userService.GetProfileAsync();
    }

    [HttpPut]
    public async Task<UserResponse> Update([FromBody] UserProfileUpdateRequest request)
    {
        return await _userService.UpdateProfileAsync(request);
    }

    // Nakon promjene lozinke stari token više ne važi, pa se korisnik mora ponovo prijaviti.
    [HttpPut("Password")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> ChangePassword([FromBody] UserPasswordChangeRequest request)
    {
        await _userService.ChangePasswordAsync(request);
        return NoContent();
    }

    [HttpGet("Image")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetImage()
    {
        var image = await _userService.GetProfileImageAsync();
        return File(image.Content, image.ContentType);
    }

    // Slika se šalje kao multipart/form-data (polje "image"), kao kod vozila (upute 5).
    [HttpPut("Image")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(FormFileExtensions.MaxImageRequestBytes)]
    [RequestFormLimits(MultipartBodyLengthLimit = FormFileExtensions.MaxImageRequestBytes)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateImage(IFormFile? image)
    {
        await _userService.SetProfileImageAsync(await image.ToImageUploadRequestAsync());
        return NoContent();
    }

    [HttpDelete("Image")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> DeleteImage()
    {
        await _userService.DeleteProfileImageAsync();
        return NoContent();
    }
}
