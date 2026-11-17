using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Čitaju svi prijavljeni (npr. filteri u mobilnoj aplikaciji), a mijenja samo administrator.
public class CategoriesController
    : BaseCRUDController<CategoryResponse, CategorySearchObject, CategoryInsertRequest, CategoryUpdateRequest, ICategoryService>
{
    public CategoriesController(ICategoryService categoryService) : base(categoryService)
    {
    }

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<CategoryResponse>> Create([FromBody] CategoryInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<CategoryResponse>> Update(int id, [FromBody] CategoryUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
