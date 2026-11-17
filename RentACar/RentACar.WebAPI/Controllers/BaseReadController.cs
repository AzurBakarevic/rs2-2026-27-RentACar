using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Generički kontroler za čitanje: GET /{kontroler}?Page=1&PageSize=10&IncludeTotalCount=true i GET /{kontroler}/{id}.
// Izuzetke (npr. nepostojeći Id → 404) pretvara ExceptionFilter, pa ovdje nema try/catch.
[ApiController]
[Route("[controller]")]
public abstract class BaseReadController<TResponse, TSearch, TService> : ControllerBase
    where TSearch : BaseSearchObject
    where TService : IBaseReadService<TResponse, TSearch>
{
    protected readonly TService _service;

    protected BaseReadController(TService service)
    {
        _service = service;
    }

    [HttpGet]
    public virtual async Task<PageResult<TResponse>> GetAll([FromQuery] TSearch? search)
    {
        return await _service.GetAllAsync(search);
    }

    [HttpGet("{id:int}")]
    public virtual async Task<TResponse> GetById(int id)
    {
        return await _service.GetByIdAsync(id);
    }
}
