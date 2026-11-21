using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// PDF izvještaji (prijava), samo za administratora (upute 5). Npr. GET /Reports/Reservations?From=2026-10-01&To=2026-10-31.
[Authorize(Roles = RoleNames.Administrator)]
[ApiController]
[Route("[controller]")]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportsController(IReportService reportService)
    {
        _reportService = reportService;
    }

    [HttpGet("Reservations")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetReservationReport([FromQuery] ReportPeriodRequest request)
    {
        var report = await _reportService.GetReservationReportAsync(request);
        return File(report.Content, report.ContentType, report.FileName);
    }

    [HttpGet("MostRentedVehicles")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetMostRentedVehiclesReport([FromQuery] ReportPeriodRequest request)
    {
        var report = await _reportService.GetMostRentedVehiclesReportAsync(request);
        return File(report.Content, report.ContentType, report.FileName);
    }
}
