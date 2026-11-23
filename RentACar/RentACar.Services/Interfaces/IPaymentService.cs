using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

public interface IPaymentService
{
    Task<PageResult<PaymentTransactionResponse>> GetAllAsync(PaymentSearchObject? search = null);

    Task<PaymentIntentResponse> CreatePaymentAsync(int reservationId);

    Task<ReservationResponse> ConfirmPaymentAsync(int reservationId);
}
