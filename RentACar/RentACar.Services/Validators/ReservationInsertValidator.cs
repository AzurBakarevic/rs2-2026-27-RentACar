using FluentValidation;
using RentACar.Model.Requests;
using RentACar.Services.Helpers;

namespace RentACar.Services.Validators;

public class ReservationInsertValidator : AbstractValidator<ReservationInsertRequest>
{
    private const int MaxEquipmentQuantity = 20;

    public ReservationInsertValidator()
    {
        RuleFor(x => x.VehicleId)
            .GreaterThan(0).WithMessage("Vozilo je obavezno.");

        RuleFor(x => x.PickupAt)
            .Cascade(CascadeMode.Stop)
            .NotEmpty().WithMessage("Vrijeme preuzimanja je obavezno.")
            .Must(x => AgencyTime.AsUtc(x) > DateTime.UtcNow).WithMessage("Vrijeme preuzimanja mora biti u budućnosti.");

        RuleFor(x => x.ReturnAt)
            .NotEmpty().WithMessage("Vrijeme vraćanja je obavezno.");

        RuleFor(x => x.ReturnAt)
            .Cascade(CascadeMode.Stop)
            .Must((request, returnAt) => AgencyTime.AsUtc(returnAt) > AgencyTime.AsUtc(request.PickupAt))
                .WithMessage("Vrijeme vraćanja mora biti poslije vremena preuzimanja.")
            .Must((request, returnAt) => ReservationRules.GetRentalDays(AgencyTime.AsUtc(request.PickupAt), AgencyTime.AsUtc(returnAt))
                                         <= ReservationRules.MaxRentalDays)
                .WithMessage($"Najam može trajati najviše {ReservationRules.MaxRentalDays} dana.")
            .When(x => x.PickupAt != default && x.ReturnAt != default);

        RuleForEach(x => x.Equipment)
            .NotNull().WithMessage("Stavka dodatne opreme nije ispravna.")
            .ChildRules(item =>
            {
                item.RuleFor(x => x.EquipmentId)
                    .GreaterThan(0).WithMessage("Oprema je obavezna.");

                item.RuleFor(x => x.Quantity)
                    .InclusiveBetween(1, MaxEquipmentQuantity)
                    .WithMessage($"Količina opreme mora biti između 1 i {MaxEquipmentQuantity}.");
            });
    }
}
