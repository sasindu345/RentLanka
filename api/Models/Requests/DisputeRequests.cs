using System;

namespace RentLanka.Api.Models.Requests;

public record CreateDisputeRequest(Guid BookingId, string Reason);

public record ResolveDisputeRequest(string AdminDecision, bool RefundRenter);
