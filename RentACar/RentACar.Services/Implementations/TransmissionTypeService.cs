using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Exceptions;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class TransmissionTypeService
    : BaseCRUDService<TransmissionType, TransmissionTypeResponse, TransmissionTypeSearchObject, TransmissionTypeInsertRequest, TransmissionTypeUpdateRequest>, ITransmissionTypeService
{
    public TransmissionTypeService(
        RentACarDbContext dbContext,
        IMapper mapper,
        IValidator<TransmissionTypeInsertRequest> insertValidator,
        IValidator<TransmissionTypeUpdateRequest> updateValidator) : base(dbContext, mapper, insertValidator, updateValidator)
    {
    }

    protected override IQueryable<TransmissionType> ApplyFilters(IQueryable<TransmissionType> query, TransmissionTypeSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Name))
        {
            query = query.Where(x => x.Name.Contains(search.Name));
        }

        return query;
    }

    protected override IQueryable<TransmissionType> ApplyOrdering(IQueryable<TransmissionType> query) => query.OrderBy(x => x.Name);

    protected override Task BeforeInsertAsync(TransmissionTypeInsertRequest request, TransmissionType entity) => EnsureNameIsUniqueAsync(entity);

    protected override Task BeforeUpdateAsync(TransmissionTypeUpdateRequest request, TransmissionType entity) => EnsureNameIsUniqueAsync(entity);

    protected override async Task BeforeDeleteAsync(TransmissionType entity)
    {
        if (await _dbContext.Vehicles.AnyAsync(x => x.TransmissionTypeId == entity.Id))
        {
            throw new ClientException("Vrsta mjenjača se ne može obrisati jer je koriste vozila.");
        }
    }

    private async Task EnsureNameIsUniqueAsync(TransmissionType entity)
    {
        entity.Name = entity.Name.Trim();

        if (await _dbContext.TransmissionTypes.AnyAsync(x => x.Name == entity.Name && x.Id != entity.Id))
        {
            throw new ClientException("Vrsta mjenjača s ovim nazivom već postoji.");
        }
    }
}
