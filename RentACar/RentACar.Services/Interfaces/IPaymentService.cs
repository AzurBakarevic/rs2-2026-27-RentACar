using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

// Plaćanje rezervacije karticom putem Stripe-a (prijava) i historija uplata i povrata.
public interface IPaymentService
{
    // Historija plaćanja: korisnik vidi svoje uplate i povrate, administrator sve.
    Task<PageResult<PaymentTransactionResponse>> GetAllAsync(PaymentSearchObject? search = null);

    // Otvara (ili ponovo koristi) Stripe plaćanje za iznos rezervacije iz baze; aplikacija s odgovorom prikazuje obrazac.
    Task<PaymentIntentResponse> CreatePaymentAsync(int reservationId);

    // Nakon što korisnik plati u aplikaciji: server kod Stripe-a provjerava da je plaćanje uspjelo (upute 7.1).
    Task<ReservationResponse> ConfirmPaymentAsync(int reservationId);
}
