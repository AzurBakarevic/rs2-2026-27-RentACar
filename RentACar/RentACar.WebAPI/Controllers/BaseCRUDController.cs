using Microsoft.AspNetCore.Mvc;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Generički kontroler za čitanje, dodavanje (201), izmjenu (200) i brisanje (204).
public abstract class BaseCRUDController<TResponse, TSearch, TInsertRequest, TUpdateRequest, TService>
    : BaseReadController<TResponse, TSearch, TService>
    where TSearch : BaseSearchObject
    where TService : IBaseCRUDService<TResponse, TSearch, TInsertRequest, TUpdateRequest>
{
    protected BaseCRUDController(TService service) : base(service)
    {
    }

    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public virtual async Task<ActionResult<TResponse>> Create([FromBody] TInsertRequest request)
    {
        var result = await _service.InsertAsync(request);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public virtual async Task<ActionResult<TResponse>> Update(int id, [FromBody] TUpdateRequest request)
    {
        return await _service.UpdateAsync(id, request);
    }

    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public virtual async Task<IActionResult> Delete(int id)
    {
        await _service.DeleteAsync(id);
        return NoContent();
    }
}
