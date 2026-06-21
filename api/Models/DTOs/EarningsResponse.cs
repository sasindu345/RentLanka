using System;
using System.Collections.Generic;

namespace RentLanka.Api.Models.DTOs;

public record EarningsResponse(
    decimal AvailableBalance,
    decimal TotalEarned,
    decimal EscrowedBalance,
    IEnumerable<PayoutResponse> Payouts);
