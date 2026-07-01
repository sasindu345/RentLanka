using System.Collections.Generic;

namespace RentLanka.Api.Models.Requests;

public record UpdateSettingsRequest(
    decimal CommissionRate,
    List<string> Categories);
