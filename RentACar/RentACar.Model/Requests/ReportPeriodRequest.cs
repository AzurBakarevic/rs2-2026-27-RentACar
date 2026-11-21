namespace RentACar.Model.Requests;

// Period izvještaja (prijava: administrator bira period od–do). Datumi su kalendarski dani po lokalnom vremenu
// agencije i oba ulaze u period, npr. From=2026-10-01&To=2026-10-31 je cijeli oktobar.
public class ReportPeriodRequest
{
    public DateOnly? From { get; set; }
    public DateOnly? To { get; set; }
}
