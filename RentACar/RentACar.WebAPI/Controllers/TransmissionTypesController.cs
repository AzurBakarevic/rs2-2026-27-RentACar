using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

public class TransmissionTypesController
    : BaseCRUDController<TransmissionTypeResponse, TransmissionTypeSearchObject, TransmissionTypeInsertRequest, TransmissionTypeUpdateRequest, ITransmissionTypeService>
{
    public TransmissionTypesController(ITransmissionTypeService transmissionTypeService) : base(transmissionTypeService)
    {
    }
}
