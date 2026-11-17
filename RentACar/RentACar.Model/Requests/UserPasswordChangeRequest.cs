namespace RentACar.Model.Requests;

// Prijavljeni korisnik mijenja vlastitu lozinku i mora potvrditi staru (upute 4). Bez Id-a: uzima se iz tokena.
public class UserPasswordChangeRequest
{
    public string OldPassword { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
    public string NewPasswordConfirm { get; set; } = string.Empty;
}
