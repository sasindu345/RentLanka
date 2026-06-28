using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Requests;

namespace RentLanka.Api.Services.Interfaces;

public interface IDisputeService
{
    Task<DisputeResponse> CreateDisputeAsync(Guid userId, CreateDisputeRequest request);
    Task<List<DisputeResponse>> GetMyDisputesAsync(Guid userId);
    Task<List<DisputeResponse>> GetAdminDisputesAsync();
    Task<DisputeResponse> ResolveDisputeAsync(Guid disputeId, Guid adminId, ResolveDisputeRequest request);
}
