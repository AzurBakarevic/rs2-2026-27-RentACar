using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Responses;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Početni ekran desktop aplikacije, samo za administratora (upute 5).
[Authorize(Roles = RoleNames.Administrator)]
[ApiController]
[Route("[controller]")]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;

    public DashboardController(IDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<DashboardResponse> Get()
    {
        return await _dashboardService.GetAsync();
    }
}
