namespace RentACar.Model.Requests;

// Prvi korak reseta lozinke (prijava): korisnik unese e-mail adresu na koju dobija kod.
public class PasswordForgotRequest
{
    public string Email { get; set; } = string.Empty;
}
