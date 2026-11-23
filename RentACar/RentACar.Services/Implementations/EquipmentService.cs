using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.Constants;
using RentACar.Model.Exceptions;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Helpers;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public class EquipmentService
    : BaseCRUDService<Equipment, EquipmentResponse, EquipmentSearchObject, EquipmentInsertRequest, EquipmentUpdateRequest>,
      IEquipmentService
{
    private readonly IAuthenticatedUserAccessor _authenticatedUser;

    public EquipmentService(
        RentACarDbContext dbContext,
        IMapper mapper,
        IValidator<EquipmentInsertRequest> insertValidator,
        IValidator<EquipmentUpdateRequest> updateValidator,
        IAuthenticatedUserAccessor authenticatedUser) : base(dbContext, mapper, insertValidator, updateValidator)
    {
        _authenticatedUser = authenticatedUser;
    }

    protected override IQueryable<Equipment> GetQuery()
    {
        var query = base.GetQuery();
        return _authenticatedUser.IsInRole(RoleNames.Administrator) ? query : query.Where(x => x.IsActive);
    }

    protected override IQueryable<Equipment> ApplyFilters(IQueryable<Equipment> query, EquipmentSearchObject search)
    {
        if (!string.IsNullOrWhiteSpace(search.Name))
        {
            query = query.Where(x => x.Name.Contains(search.Name));
        }

        if (search.IsActive.HasValue)
        {
            query = query.Where(x => x.IsActive == search.IsActive.Value);
        }

        return query;
    }

    protected override IQueryable<Equipment> ApplyOrdering(IQueryable<Equipment> query) => query.OrderBy(x => x.Name);

    protected override Task BeforeInsertAsync(EquipmentInsertRequest request, Equipment entity) => EnsureNameIsUniqueAsync(entity);

    protected override Task BeforeUpdateAsync(EquipmentUpdateRequest request, Equipment entity) => EnsureNameIsUniqueAsync(entity);

    protected override async Task BeforeDeleteAsync(Equipment entity)
    {
        if (await _dbContext.ReservationEquipment.AnyAsync(x => x.EquipmentId == entity.Id))
        {
            throw new ClientException(DeleteBlockedReasons.EquipmentInUse);
        }
    }

    private async Task EnsureNameIsUniqueAsync(Equipment entity)
    {
        entity.Name = entity.Name.Trim();

        if (await _dbContext.Equipment.AnyAsync(x => x.Name == entity.Name && x.Id != entity.Id))
        {
            throw new ClientException("Oprema s ovim nazivom već postoji.");
        }
    }
}
