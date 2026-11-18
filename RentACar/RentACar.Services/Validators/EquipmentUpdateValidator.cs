using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class EquipmentUpdateValidator : AbstractValidator<EquipmentUpdateRequest>
{
    public EquipmentUpdateValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Naziv je obavezan.")
            .MaximumLength(100).WithMessage("Naziv može imati najviše 100 znakova.");

        // Oprema može biti i besplatna (0 KM).
        RuleFor(x => x.PricePerDay)
            .GreaterThanOrEqualTo(0).WithMessage("Cijena po danu ne može biti negativna.")
            .LessThanOrEqualTo(1000).WithMessage("Cijena po danu može biti najviše 1000 KM.")
            .PrecisionScale(10, 2, true).WithMessage("Cijena po danu može imati najviše dvije decimale.");

        RuleFor(x => x.Quantity)
            .InclusiveBetween(0, 1000).WithMessage("Količina mora biti između 0 i 1000.");
    }
}
