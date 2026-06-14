using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using RentLanka.Application.Common.Interfaces;

namespace RentLanka.Api.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth");

        group.MapPost("/register", async (RegisterRequest request, IIdentityService identityService) =>
        {
            var (succeeded, userId, error) = await identityService.CreateUserAsync(
                request.Email, 
                request.Password, 
                request.FirstName, 
                request.LastName, 
                request.PhoneNumber);

            if (!succeeded)
            {
                return Results.BadRequest(new { Error = error });
            }

            return Results.Ok(new { UserId = userId, Message = "User registered successfully." });
        });

        group.MapPost("/login", async (LoginRequest request, IIdentityService identityService) =>
        {
            var (succeeded, token, error) = await identityService.LoginAsync(request.Email, request.Password);

            if (!succeeded)
            {
                return Results.Unauthorized();
            }

            return Results.Ok(new { Token = token });
        });
    }
}

public record RegisterRequest(string Email, string Password, string FirstName, string LastName, string PhoneNumber);
public record LoginRequest(string Email, string Password);
