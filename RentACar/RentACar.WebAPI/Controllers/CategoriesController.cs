using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

public class CategoriesController
    : BaseCRUDController<CategoryResponse, CategorySearchObject, CategoryInsertRequest, CategoryUpdateRequest, ICategoryService>
{
    public CategoriesController(ICategoryService categoryService) : base(categoryService)
    {
    }
}
