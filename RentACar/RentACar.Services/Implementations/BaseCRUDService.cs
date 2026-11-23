using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using RentACar.Model.SearchObjects;
using RentACar.Services.Database;
using RentACar.Services.Interfaces;

namespace RentACar.Services.Implementations;

public abstract class BaseCRUDService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>
    : BaseReadService<TEntity, TResponse, TSearch>,
      IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest>
    where TEntity : class, IEntity
    where TResponse : class
    where TSearch : BaseSearchObject, new()
{
    protected readonly IValidator<TInsertRequest> _insertValidator;
    protected readonly IValidator<TUpdateRequest> _updateValidator;

    protected BaseCRUDService(
        RentACarDbContext dbContext,
        IMapper mapper,
        IValidator<TInsertRequest> insertValidator,
        IValidator<TUpdateRequest> updateValidator) : base(mapper, dbContext)
    {
        _insertValidator = insertValidator;
        _updateValidator = updateValidator;
    }

    public virtual async Task<TResponse> InsertAsync(TInsertRequest request)
    {
        await _insertValidator.ValidateAndThrowAsync(request);

        var entity = MapInsertRequestToEntity(request);

        await BeforeInsertAsync(request, entity);

        _dbContext.Set<TEntity>().Add(entity);
        await _dbContext.SaveChangesAsync();

        return await GetByIdAsync(entity.Id);
    }

    public virtual async Task<TResponse> UpdateAsync(int id, TUpdateRequest request)
    {
        await _updateValidator.ValidateAndThrowAsync(request);

        var entity = await GetQuery().FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found.");

        MapUpdateRequestToEntity(request, entity);

        await BeforeUpdateAsync(request, entity);

        await _dbContext.SaveChangesAsync();

        return await GetByIdAsync(id);
    }

    public virtual async Task DeleteAsync(int id)
    {
        var entity = await GetQuery().FirstOrDefaultAsync(x => x.Id == id)
            ?? throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found.");

        await BeforeDeleteAsync(entity);

        _dbContext.Set<TEntity>().Remove(entity);
        await _dbContext.SaveChangesAsync();
    }

    protected virtual TEntity MapInsertRequestToEntity(TInsertRequest request)
        => _mapper.Map<TEntity>(request!);

    protected virtual void MapUpdateRequestToEntity(TUpdateRequest request, TEntity entity)
        => _mapper.Map(request, entity);

    protected virtual Task BeforeInsertAsync(TInsertRequest request, TEntity entity) => Task.CompletedTask;

    protected virtual Task BeforeUpdateAsync(TUpdateRequest request, TEntity entity) => Task.CompletedTask;

    protected virtual Task BeforeDeleteAsync(TEntity entity) => Task.CompletedTask;
}
