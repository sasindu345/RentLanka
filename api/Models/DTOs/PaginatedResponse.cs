using System.Collections.Generic;

namespace RentLanka.Api.Models.DTOs;

public record PaginatedResponse<T>(
    List<T> Items,
    int Total,
    int Page,
    int PageSize);
