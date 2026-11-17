using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;

namespace RentACar.WebAPI.Controllers;

// Čitaju svi prijavljeni (npr. filteri u mobilnoj aplikaciji), a mijenja samo administrator.
public class BrandsController
    : BaseCRUDController<BrandResponse, BrandSearchObject, BrandInsertRequest, BrandUpdateRequest, IBrandService>
{
    public BrandsController(IBrandService brandService) : base(brandService)
    {
    }

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<BrandResponse>> Create([FromBody] BrandInsertRequest request)
        => base.Create(request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<ActionResult<BrandResponse>> Update(int id, [FromBody] BrandUpdateRequest request)
        => base.Update(id, request);

    [Authorize(Roles = RoleNames.Administrator)]
    public override Task<IActionResult> Delete(int id)
        => base.Delete(id);
}
