namespace RentACar.Model.Responses;

public class DashboardResponse
{
    public int VehicleCount { get; set; }

    public int CustomerCount { get; set; }

    public int ActiveReservationCount { get; set; }

    public int AwaitingConfirmationCount { get; set; }

    public List<DailyReservationCountResponse> ReservationsPerDay { get; set; } = new();
}
