namespace RentACar.Model.SearchObjects;

public class UserSearchObject : BaseSearchObject
{
    // Dio imena, prezimena, korisničkog imena ili e-maila.
    public string? Text { get; set; }

    public int? RoleId { get; set; }

    public bool? IsActive { get; set; }
}
