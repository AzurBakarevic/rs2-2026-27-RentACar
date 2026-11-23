using FluentValidation;
using RentACar.Model.Requests;

namespace RentACar.Services.Validators;

public class VehicleInsertValidator : AbstractValidator<VehicleInsertRequest>
{
    private const int MinProductionYear = 1990;

    public VehicleInsertValidator()
    {
        RuleFor(x => x.RegistrationNumber)
            .NotEmpty().WithMessage("Registracija je obavezna.")
            .MaximumLength(20).WithMessage("Registracija može imati najviše 20 znakova.")
            .Matches("^[A-Za-z0-9 -]+$").WithMessage("Registracija smije sadržavati samo slova bez kvačica, brojeve, razmak i crticu.");

        RuleFor(x => x.ProductionYear)
            .InclusiveBetween(MinProductionYear, DateTime.UtcNow.Year + 1)
            .WithMessage($"Godina proizvodnje mora biti između {MinProductionYear} i {DateTime.UtcNow.Year + 1}.");

        RuleFor(x => x.SeatCount)
            .InclusiveBetween(1, 9).WithMessage("Broj sjedišta mora biti između 1 i 9.");

        RuleFor(x => x.Description)
            .MaximumLength(1000).WithMessage("Opis može imati najviše 1000 znakova.");

        RuleFor(x => x.PricePerDay)
            .GreaterThan(0).WithMessage("Cijena po danu mora biti veća od 0.")
            .LessThanOrEqualTo(10000).WithMessage("Cijena po danu može biti najviše 10000 KM.")
            .PrecisionScale(10, 2, true).WithMessage("Cijena po danu može imati najviše dvije decimale.");

        RuleFor(x => x.VehicleModelId)
            .GreaterThan(0).WithMessage("Model je obavezan.");

        RuleFor(x => x.CategoryId)
            .GreaterThan(0).WithMessage("Kategorija je obavezna.");

        RuleFor(x => x.FuelTypeId)
            .GreaterThan(0).WithMessage("Vrsta goriva je obavezna.");

        RuleFor(x => x.TransmissionTypeId)
            .GreaterThan(0).WithMessage("Vrsta mjenjača je obavezna.");
    }
}
