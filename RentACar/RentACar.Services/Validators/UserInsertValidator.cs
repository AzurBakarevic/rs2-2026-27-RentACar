using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class UserInsertValidator : AbstractValidator<UserInsertRequest>
{
    public UserInsertValidator()
    {
        Include(new UserDetailsValidator());

        RuleFor(x => x.Password).ValidPassword();

        RuleFor(x => x.PasswordConfirm)
            .Equal(x => x.Password).WithMessage("Lozinke se ne podudaraju.");

        RuleFor(x => x.RoleId)
            .GreaterThan(0).WithMessage("Uloga je obavezna.");
    }
}
