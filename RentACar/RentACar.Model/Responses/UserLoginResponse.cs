namespace RentACar.Model.Responses;

public class UserLoginResponse
{
    public string AccessToken { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }

    public int UserId { get; set; }
    public string Username { get; set; } = string.Empty;

    public string Role { get; set; } = string.Empty;
}
