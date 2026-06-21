using System;

namespace RentLanka.Api.Models.Requests;

public record ManualBlockRequest(
    DateTime StartDate,
    DateTime EndDate);
