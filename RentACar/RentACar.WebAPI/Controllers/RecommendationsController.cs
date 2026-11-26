using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Responses;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

[Authorize(Roles = RoleNames.Customer)]
[ApiController]
[Route("[controller]")]
public class RecommendationsController : ControllerBase
{
    private readonly IRecommendationService _recommendationService;

    public RecommendationsController(IRecommendationService recommendationService)
    {
        _recommendationService = recommendationService;
    }

    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<List<RecommendationResponse>> Get()
    {
        return await _recommendationService.GetAsync();
    }
}
