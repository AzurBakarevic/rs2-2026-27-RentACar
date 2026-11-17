using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

public class VehicleModelsController
    : BaseCRUDController<VehicleModelResponse, VehicleModelSearchObject, VehicleModelInsertRequest, VehicleModelUpdateRequest, IVehicleModelService>
{
    public VehicleModelsController(IVehicleModelService vehicleModelService) : base(vehicleModelService)
    {
    }
}
