using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

public class FuelTypesController
    : BaseCRUDController<FuelTypeResponse, FuelTypeSearchObject, FuelTypeInsertRequest, FuelTypeUpdateRequest, IFuelTypeService>
{
    public FuelTypesController(IFuelTypeService fuelTypeService) : base(fuelTypeService)
    {
    }
}
