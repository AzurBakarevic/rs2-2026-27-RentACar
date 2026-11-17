namespace RentACar.Model.Responses;

public class PageResult<T>
{
    public List<T> Items { get; set; } = new();

    // Ukupan broj zapisa koji odgovaraju filteru; popunjava se samo uz IncludeTotalCount=true.
    public int? TotalCount { get; set; }
}
