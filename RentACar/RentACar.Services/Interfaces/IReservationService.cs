using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

// Rezervacije se ne mijenjaju ni ne brišu kroz CRUD (prijava: rezervacije se ne brišu), nego samo kroz akcije state machine-a.
public interface IReservationService : IBaseReadService<ReservationResponse, ReservationSearchObject>
{
    // Obračun prije potvrde, bez upisa (iste provjere kao kreiranje).
    Task<ReservationCalculationResponse> CalculateAsync(ReservationInsertRequest request);

    Task<ReservationResponse> InsertAsync(ReservationInsertRequest request);

    Task<ReservationResponse> ConfirmAsync(int id);

    Task<ReservationResponse> RejectAsync(int id, ReservationRejectRequest request);

    Task<ReservationResponse> CompleteAsync(int id);

    Task<ReservationResponse> CancelAsync(int id, ReservationCancelRequest? request);
}
