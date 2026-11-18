using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

public interface IVehicleService
    : IBaseCRUDService<VehicleResponse, VehicleSearchObject, VehicleInsertRequest, VehicleUpdateRequest>
{
    // Slika vozila (JPEG ili PNG); KeyNotFoundException (404) ako vozilo ne postoji ili nema sliku.
    Task<ImageResponse> GetImageAsync(int id);

    // Postavlja ili zamjenjuje sliku nakon provjere veličine, MIME tipa i magic bytes (upute 5).
    Task SetImageAsync(int id, ImageUploadRequest request);
}
