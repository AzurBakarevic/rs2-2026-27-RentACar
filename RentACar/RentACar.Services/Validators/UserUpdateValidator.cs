using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class UserUpdateValidator : AbstractValidator<UserUpdateRequest>
{
    public UserUpdateValidator()
    {
        Include(new UserDetailsValidator());

        When(x => !string.IsNullOrEmpty(x.Password) || !string.IsNullOrEmpty(x.PasswordConfirm), () =>
        {
            RuleFor(x => x.Password).ValidPassword();

            RuleFor(x => x.PasswordConfirm)
                .Equal(x => x.Password).WithMessage("Lozinke se ne podudaraju.");
        });

        RuleFor(x => x.RoleId)
            .GreaterThan(0).WithMessage("Uloga je obavezna.");
    }
}
