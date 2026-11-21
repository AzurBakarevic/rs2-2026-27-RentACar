using RentACar.Model.Responses;

namespace RentACar.Services.Interfaces;

public interface IDashboardService
{
    Task<DashboardResponse> GetAsync();
}
