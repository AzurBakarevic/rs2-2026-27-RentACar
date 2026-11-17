namespace RentACar.Model.Responses;

public class UserLoginResponse
{
    public string AccessToken { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }

    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;

    // Klijent po ulozi bira šta prikazuje (desktop = Administrator, mobilna = Korisnik).
    public string Role { get; set; } = string.Empty;
}
