using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Čitaju svi prijavljeni (korisnik samo svoje rezervacije). Rezervaciju kreira korisnik (mobilna aplikacija),
// a status se mijenja samo kroz akcije state machine-a; izmjene i brisanja nema (prijava: rezervacije se ne brišu).
public class ReservationsController : BaseReadController<ReservationResponse, ReservationSearchObject, IReservationService>
{
    public ReservationsController(IReservationService reservationService) : base(reservationService)
    {
    }

    [Authorize(Roles = RoleNames.Customer)]
    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ReservationResponse>> Create([FromBody] ReservationInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // Obračun prije potvrde (broj dana, cijena vozila, sezonski dodatak, oprema, ukupno), bez upisa.
    [Authorize(Roles = RoleNames.Customer)]
    [HttpPost("Calculate")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ReservationCalculationResponse> Calculate([FromBody] ReservationInsertRequest request)
    {
        return await _service.CalculateAsync(request);
    }

    [Authorize(Roles = RoleNames.Administrator)]
    [HttpPost("{id:int}/Confirm")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ReservationResponse> Confirm(int id)
    {
        return await _service.ConfirmAsync(id);
    }

    [Authorize(Roles = RoleNames.Administrator)]
    [HttpPost("{id:int}/Reject")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ReservationResponse> Reject(int id, [FromBody] ReservationRejectRequest request)
    {
        return await _service.RejectAsync(id, request);
    }

    [Authorize(Roles = RoleNames.Administrator)]
    [HttpPost("{id:int}/Complete")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ReservationResponse> Complete(int id)
    {
        return await _service.CompleteAsync(id);
    }

    // Otkazuju i korisnik (svoju rezervaciju) i administrator; pravila za svakog su u state machine-u.
    // Tijelo nije obavezno, jer korisnik ne mora navesti razlog.
    [HttpPost("{id:int}/Cancel")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ReservationResponse> Cancel(int id,
        [FromBody(EmptyBodyBehavior = EmptyBodyBehavior.Allow)] ReservationCancelRequest? request)
    {
        return await _service.CancelAsync(id, request);
    }
}
