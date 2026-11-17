using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class VehicleModelInsertValidator : AbstractValidator<VehicleModelInsertRequest>
{
    public VehicleModelInsertValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Naziv je obavezan.")
            .MaximumLength(50).WithMessage("Naziv može imati najviše 50 znakova.");

        RuleFor(x => x.BrandId)
            .GreaterThan(0).WithMessage("Marka je obavezna.");
    }
}
