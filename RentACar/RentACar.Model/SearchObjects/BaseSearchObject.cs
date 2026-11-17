namespace RentACar.Model.SearchObjects;

public class BaseSearchObject
{
    public const int DefaultPageSize = 10;

    // Najveća stranica (upute 8.2); veća vrijednost se u servisu svodi na ovu, a lista se nikad ne vraća cijela.
    public const int MaxPageSize = 100;

    public int? Page { get; set; } = 1;

    public int? PageSize { get; set; } = DefaultPageSize;

    public bool? IncludeTotalCount { get; set; } = false;
}
