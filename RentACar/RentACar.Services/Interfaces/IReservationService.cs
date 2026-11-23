using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

public interface IReservationService : IBaseReadService<ReservationResponse, ReservationSearchObject>
{
    Task<ReservationCalculationResponse> CalculateAsync(ReservationInsertRequest request);

    Task<ReservationResponse> InsertAsync(ReservationInsertRequest request);

    Task<ReservationResponse> ConfirmAsync(int id);

    Task<ReservationResponse> RejectAsync(int id, ReservationRejectRequest request);

    Task<ReservationResponse> CompleteAsync(int id);

    Task<ReservationResponse> CancelAsync(int id, ReservationCancelRequest? request);
}
