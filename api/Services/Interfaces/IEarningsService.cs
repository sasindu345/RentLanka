using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Requests;

namespace RentLanka.Api.Services.Interfaces;

public interface IEarningsService
{
    Task<EarningsResponse> GetHostEarningsAsync(Guid hostId);
    Task<(bool Succeeded, string? Error)> RequestPayoutAsync(Guid hostId, PayoutRequest request);
    Task<IEnumerable<PayoutResponse>> GetAllPayoutsAsync();
    Task<IEnumerable<PaymentResponse>> GetAllPaymentsAsync();
    Task<(bool Succeeded, string? Error)> ApprovePayoutAsync(Guid payoutId);
}
