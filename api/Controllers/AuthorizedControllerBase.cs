using System;
using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;

namespace RentLanka.Api.Controllers;

public abstract class AuthorizedControllerBase : ControllerBase
{
    protected Guid GetUserId()
    {
        var claimValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(claimValue))
        {
            throw new UnauthorizedAccessException("User is not authenticated.");
        }

        return Guid.Parse(claimValue);
    }
}
