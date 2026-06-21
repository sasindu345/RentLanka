namespace RentLanka.Api.Models.DTOs;

public record AdminDashboardStats(
    int TotalUsers,
    int ActiveListings,
    int PendingKycCount,
    int TotalBookingsCount,
    int OpenDisputesCount);
