using RentACar.Model.Requests;
using RentACar.Model.Responses;

namespace RentACar.Services.Interfaces;

public interface IReportService
{
    Task<FileResponse> GetReservationReportAsync(ReportPeriodRequest request);

    Task<FileResponse> GetMostRentedVehiclesReportAsync(ReportPeriodRequest request);
}
