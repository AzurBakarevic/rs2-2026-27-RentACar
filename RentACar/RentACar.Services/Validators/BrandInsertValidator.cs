using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class BrandInsertValidator : AbstractValidator<BrandInsertRequest>
{
    public BrandInsertValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Naziv je obavezan.")
            .MaximumLength(50).WithMessage("Naziv može imati najviše 50 znakova.");
    }
}
