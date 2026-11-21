using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Čitaju svi prijavljeni (mobilna: recenzije u detaljima vozila; desktop: pregled svih recenzija).
// Recenziju ostavlja korisnik (mobilna aplikacija), a uklanja administrator; izmjene nema.
public class ReviewsController : BaseReadController<ReviewResponse, ReviewSearchObject, IReviewService>
{
    public ReviewsController(IReviewService reviewService) : base(reviewService)
    {
    }

    [Authorize(Roles = RoleNames.Customer)]
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ReviewResponse>> Create([FromBody] ReviewInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [Authorize(Roles = RoleNames.Administrator)]
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        await _service.DeleteAsync(id);
        return NoContent();
    }
}
