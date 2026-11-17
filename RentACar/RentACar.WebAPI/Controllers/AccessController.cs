using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Services.Interfaces;
using RentACar.WebAPI.Services.AccessManager;

namespace RentACar.WebAPI.Controllers;

// Prijava, registracija i odjava. [AllowAnonymous] je samo na prijavi i registraciji (upute 5).
[Authorize]
[ApiController]
[Route("[controller]")]
public class AccessController : ControllerBase
{
    private readonly IAccessManager _accessManager;
    private readonly IUserService _userService;

    public AccessController(IAccessManager accessManager, IUserService userService)
    {
        _accessManager = accessManager;
        _userService = userService;
    }

    // Kredencijali idu u body POST zahtjeva, nikad u query string (upute 5).
    [AllowAnonymous]
    [HttpPost("Login")]
    public async Task<UserLoginResponse> Login([FromBody] UserLoginRequest request)
    {
        return await _accessManager.LoginAsync(request);
    }

    // Registracija iz mobilne aplikacije; uloga je uvijek Korisnik.
    [AllowAnonymous]
    [HttpPost("Register")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    public async Task<ActionResult<UserResponse>> Register([FromBody] UserRegisterRequest request)
    {
        var result = await _userService.RegisterAsync(request);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // Poništava sve tokene prijavljenog korisnika na serveru (upute 5).
    [HttpPost("Logout")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Logout()
    {
        await _accessManager.LogoutAsync();
        return NoContent();
    }
}
