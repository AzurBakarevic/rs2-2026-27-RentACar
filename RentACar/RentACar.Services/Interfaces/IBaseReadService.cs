using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

public interface IBaseReadService<TResponse, TSearch>
    where TSearch : BaseSearchObject
{
    Task<TResponse> GetByIdAsync(int id);
    Task<PageResult<TResponse>> GetAllAsync(TSearch? search = null);
}
