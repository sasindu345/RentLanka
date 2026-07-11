namespace RentLanka.Api.Models.DTOs;

public record TimeSeriesPoint(string Label, int Bookings, decimal Revenue, string Date);

public record CategoryShare(string Label, int Count, int Percentage);

public record VerificationSegment(string Label, int Percentage);

public record EscrowStats(
    decimal TotalTransacted,
    decimal EscrowReserves,
    decimal ReleasedToOwners,
    int EscrowPercent,
    int PayoutsPercent,
    int DisputesPercent);

public record SystemEvent(string Message, string Time, string Type);

public record AdminDashboardStats(
    int TotalUsers,
    int ActiveListings,
    int PendingKycCount,
    int TotalBookingsCount,
    int OpenDisputesCount,
    IEnumerable<TimeSeriesPoint>? TimeSeries7d = null,
    IEnumerable<TimeSeriesPoint>? TimeSeries30d = null,
    IEnumerable<CategoryShare>? Categories = null,
    IEnumerable<VerificationSegment>? Verifications = null,
    EscrowStats? Escrow = null,
    IEnumerable<SystemEvent>? RecentEvents = null);
