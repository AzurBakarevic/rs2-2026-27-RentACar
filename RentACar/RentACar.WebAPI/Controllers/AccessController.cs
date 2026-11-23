using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Services.Interfaces;
using RentACar.WebAPI.Services.AccessManager;

namespace RentACar.WebAPI.Controllers;

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

    [AllowAnonymous]
    [HttpPost("Login")]
    public async Task<UserLoginResponse> Login([FromBody] UserLoginRequest request)
    {
        return await _accessManager.LoginAsync(request);
    }

    [AllowAnonymous]
    [HttpPost("Register")]
    [ProducesResponseType(StatusCodes.Status201Created)]
    public async Task<ActionResult<UserResponse>> Register([FromBody] UserRegisterRequest request)
    {
        var result = await _userService.RegisterAsync(request);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [AllowAnonymous]
    [HttpPost("ForgotPassword")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> ForgotPassword([FromBody] PasswordForgotRequest request)
    {
        await _userService.RequestPasswordResetAsync(request);
        return NoContent();
    }

    [AllowAnonymous]
    [HttpPost("ResetPassword")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> ResetPassword([FromBody] PasswordResetRequest request)
    {
        await _userService.ResetPasswordAsync(request);
        return NoContent();
    }

    [HttpPost("Logout")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    public async Task<IActionResult> Logout()
    {
        await _accessManager.LogoutAsync();
        return NoContent();
    }
}
