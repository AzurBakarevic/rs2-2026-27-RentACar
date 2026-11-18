using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class VehicleMaintenanceInsertValidator : AbstractValidator<VehicleMaintenanceInsertRequest>
{
    public VehicleMaintenanceInsertValidator()
    {
        RuleFor(x => x.VehicleId)
            .GreaterThan(0).WithMessage("Vozilo je obavezno.");

        RuleFor(x => x.StartAt)
            .NotEmpty().WithMessage("Početak servisa je obavezan.");

        RuleFor(x => x.EndAt)
            .NotEmpty().WithMessage("Kraj servisa je obavezan.")
            .GreaterThan(x => x.StartAt).WithMessage("Kraj servisa mora biti poslije početka.");

        RuleFor(x => x.Description)
            .NotEmpty().WithMessage("Opis je obavezan.")
            .MaximumLength(500).WithMessage("Opis može imati najviše 500 znakova.");

        RuleFor(x => x.Cost)
            .GreaterThanOrEqualTo(0).WithMessage("Trošak ne može biti negativan.")
            .LessThanOrEqualTo(100000).WithMessage("Trošak može biti najviše 100000 KM.")
            .PrecisionScale(10, 2, true).WithMessage("Trošak može imati najviše dvije decimale.");
    }
}
