using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentACar.Model.Constants;
using RentACar.Model.Requests;
using RentACar.Model.Responses;
using RentACar.Model.SearchObjects;
using RentACar.Services.Interfaces;
using RentACar.WebAPI.Extensions;

namespace RentACar.WebAPI.Controllers;

[Authorize(Roles = RoleNames.Administrator)]
public class UsersController
    : BaseCRUDController<UserResponse, UserSearchObject, UserInsertRequest, UserUpdateRequest, IUserService>
{
    public UsersController(IUserService userService) : base(userService)
    {
    }

    [HttpGet("{id:int}/Image")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetImage(int id)
    {
        var image = await _service.GetImageAsync(id);
        return File(image.Content, image.ContentType);
    }

    [HttpPut("{id:int}/Image")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(FormFileExtensions.MaxImageRequestBytes)]
    [RequestFormLimits(MultipartBodyLengthLimit = FormFileExtensions.MaxImageRequestBytes)]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateImage(int id, IFormFile? image)
    {
        await _service.SetImageAsync(id, await image.ToImageUploadRequestAsync());
        return NoContent();
    }

    [HttpDelete("{id:int}/Image")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteImage(int id)
    {
        await _service.DeleteImageAsync(id);
        return NoContent();
    }
}
