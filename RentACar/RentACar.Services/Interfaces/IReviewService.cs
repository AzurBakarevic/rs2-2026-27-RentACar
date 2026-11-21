using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

// Recenzije vozila (prijava): korisnik ostavlja jednu recenziju za završenu rezervaciju, a administrator
// ih pregleda i uklanja neprimjerene. Izmjene recenzije nema.
public interface IReviewService : IBaseReadService<ReviewResponse, ReviewSearchObject>
{
    Task<ReviewResponse> InsertAsync(ReviewInsertRequest request);

    Task DeleteAsync(int id);
}
