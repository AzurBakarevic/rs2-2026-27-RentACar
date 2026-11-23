using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

public interface IReviewService : IBaseReadService<ReviewResponse, ReviewSearchObject>
{
    Task<ReviewResponse> InsertAsync(ReviewInsertRequest request);

    Task DeleteAsync(int id);
}
