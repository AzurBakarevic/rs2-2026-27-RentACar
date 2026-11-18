using FluentValidation;
using RentACar.Model.Requests;
using RentACar.Services.Helpers;

namespace RentACar.Services.Validators;

// Upload slike (upute 5): veličina, dozvoljen MIME tip i da stvarni sadržaj (magic bytes) odgovara tom tipu.
public class ImageUploadValidator : AbstractValidator<ImageUploadRequest>
{
    public const int MaxSizeInBytes = 2 * 1024 * 1024;

    public ImageUploadValidator()
    {
        RuleFor(x => x.Content)
            .Cascade(CascadeMode.Stop)
            .NotEmpty().WithMessage("Odaberite sliku.")
            .Must(content => content.Length <= MaxSizeInBytes).WithMessage("Slika može imati najviše 2 MB.");

        // Provjerava se tek kad je sadržaj ispravne veličine, da se ne vrati više poruka za isti fajl.
        RuleFor(x => x.ContentType)
            .Cascade(CascadeMode.Stop)
            .Must(contentType => contentType != null && ImageFormat.AllowedContentTypes.Contains(Normalize(contentType)))
            .WithMessage("Dozvoljene su samo slike u formatu JPG ili PNG.")
            .Must((request, contentType) => ImageFormat.DetectContentType(request.Content) == Normalize(contentType))
            .WithMessage("Sadržaj fajla ne odgovara formatu slike.")
            .When(x => x.Content.Length is > 0 and <= MaxSizeInBytes);
    }

    private static string? Normalize(string? contentType) => contentType?.Trim().ToLowerInvariant();
}
