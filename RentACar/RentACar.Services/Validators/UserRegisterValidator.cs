using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class UserRegisterValidator : AbstractValidator<UserRegisterRequest>
{
    public UserRegisterValidator()
    {
        Include(new UserDetailsValidator());

        RuleFor(x => x.Password).ValidPassword();

        RuleFor(x => x.PasswordConfirm)
            .Equal(x => x.Password).WithMessage("Lozinke se ne podudaraju.");
    }
}
