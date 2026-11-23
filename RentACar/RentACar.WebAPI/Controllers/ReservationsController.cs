using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.ModelBinding;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

public class ReservationsController : BaseReadController<ReservationResponse, ReservationSearchObject, IReservationService>
{
    private readonly IPaymentService _paymentService;

    public ReservationsController(IReservationService reservationService, IPaymentService paymentService) : base(reservationService)
    {
        _paymentService = paymentService;
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

    [Authorize(Roles = RoleNames.Customer)]
    [HttpPost("Calculate")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ReservationCalculationResponse> Calculate([FromBody] ReservationInsertRequest request)
    {
        return await _service.CalculateAsync(request);
    }

    [Authorize(Roles = RoleNames.Customer)]
    [HttpPost("{id:int}/Payment")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<PaymentIntentResponse> CreatePayment(int id)
    {
        return await _paymentService.CreatePaymentAsync(id);
    }

    [Authorize(Roles = RoleNames.Customer)]
    [HttpPost("{id:int}/Payment/Confirm")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ReservationResponse> ConfirmPayment(int id)
    {
        return await _paymentService.ConfirmPaymentAsync(id);
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
