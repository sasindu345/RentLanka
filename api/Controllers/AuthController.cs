using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IIdentityService _identityService;

    public AuthController(IIdentityService identityService)
    {
        _identityService = identityService;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        var (succeeded, userId, error) = await _identityService.CreateUserAsync(
            request.Email, 
            request.Password, 
            request.FirstName, 
            request.LastName, 
            request.PhoneNumber,
            request.Role);

        if (!succeeded)
        {
            return BadRequest(new { Error = error });
        }

        return Ok(new { UserId = userId, Message = "User registered successfully." });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var (succeeded, token, error) = await _identityService.LoginAsync(request.Email, request.Password);

        if (!succeeded)
        {
            return Unauthorized(new { Error = error });
        }

        return Ok(new { Token = token });
    }
}
