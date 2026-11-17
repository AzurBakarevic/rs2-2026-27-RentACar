using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class UserProfileUpdateValidator : AbstractValidator<UserProfileUpdateRequest>
{
    public UserProfileUpdateValidator()
    {
        Include(new UserDetailsValidator());
    }
}
