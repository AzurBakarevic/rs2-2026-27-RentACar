using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

public interface IVehicleService
    : IBaseCRUDService<VehicleResponse, VehicleSearchObject, VehicleInsertRequest, VehicleUpdateRequest>
{
    Task<ImageResponse> GetImageAsync(int id);

    Task SetImageAsync(int id, ImageUploadRequest request);
}
