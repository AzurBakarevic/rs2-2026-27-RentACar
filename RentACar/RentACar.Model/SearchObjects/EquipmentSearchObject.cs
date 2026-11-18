namespace RentACar.Model.SearchObjects;

public class EquipmentSearchObject : BaseSearchObject
{
    // Dio naziva (bez obzira na velika/mala slova).
    public string? Name { get; set; }

    // Filter za administratora; korisnik uvijek vidi samo aktivnu opremu.
    public bool? IsActive { get; set; }
}
