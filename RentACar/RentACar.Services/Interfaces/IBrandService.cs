using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

public interface IBrandService
    : IBaseCRUDService<BrandResponse, BrandSearchObject, BrandInsertRequest, BrandUpdateRequest>
{
}
