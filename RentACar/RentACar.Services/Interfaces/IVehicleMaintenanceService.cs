using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;

namespace RentACar.Services.Interfaces;

public interface IVehicleMaintenanceService
    : IBaseCRUDService<VehicleMaintenanceResponse, VehicleMaintenanceSearchObject, VehicleMaintenanceInsertRequest, VehicleMaintenanceUpdateRequest>
{
}
