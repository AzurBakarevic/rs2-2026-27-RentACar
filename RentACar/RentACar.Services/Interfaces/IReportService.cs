using RentACar.Model.Requests;
using RentACar.Model.Responses;

namespace RentACar.Services.Interfaces;

// PDF izvještaji za administratora (prijava). Oba obuhvataju rezervacije s preuzimanjem vozila u odabranom periodu,
// pa se rezervacija broji u tačno jednom periodu, a prihod oba izvještaja za isti period je isti.
public interface IReportService
{
    // Sve rezervacije u periodu (korisnik, vozilo, trajanje, status, iznos), ukupan broj i ukupan prihod.
    Task<FileResponse> GetReservationReportAsync(ReportPeriodRequest request);

    // Vozila po broju plaćenih rezervacija u periodu, s ostvarenim prihodom.
    Task<FileResponse> GetMostRentedVehiclesReportAsync(ReportPeriodRequest request);
}
