using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

public class BrandsController
    : BaseCRUDController<BrandResponse, BrandSearchObject, BrandInsertRequest, BrandUpdateRequest, IBrandService>
{
    public BrandsController(IBrandService brandService) : base(brandService)
    {
    }
}
