using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Hosting;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;
using Sentry;

namespace RentLanka.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[EnableRateLimiting("AuthLimit")]
public class AuthController : ControllerBase
{
    private readonly IIdentityService _identityService;
    private readonly IVerificationService _verificationService;
    private readonly IWebHostEnvironment _environment;

    public AuthController(
        IIdentityService identityService,
        IVerificationService verificationService,
        IWebHostEnvironment environment)
    {
        _identityService = identityService;
        _verificationService = verificationService;
        _environment = environment;
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
            SentrySdk.CaptureMessage($"Registration failed for {request.Email}: {error}", SentryLevel.Warning);
            return BadRequest(new { Error = error });
        }

        // Generate and send email verification token automatically
        var token = await _verificationService.GenerateEmailVerificationTokenAsync(userId);

        if (_environment.IsDevelopment())
        {
            return Ok(new { UserId = userId, Message = "User registered successfully.", DevToken = token });
        }

        return Ok(new { UserId = userId, Message = "User registered successfully. Verification email sent." });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var (succeeded, token, refreshToken, error) = await _identityService.LoginAsync(request.Email, request.Password);

        if (!succeeded)
        {
            SentrySdk.CaptureMessage($"Login failed for {request.Email}: {error}", SentryLevel.Warning);
            return Unauthorized(new { Error = error });
        }

        return Ok(new { Token = token, RefreshToken = refreshToken });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest request)
    {
        var (succeeded, token, refreshToken, error) = await _identityService.RefreshTokenAsync(request.Token, request.RefreshToken);

        if (!succeeded)
        {
            SentrySdk.CaptureMessage($"Token refresh failed: {error}", SentryLevel.Warning);
            return BadRequest(new { Error = error });
        }

        return Ok(new { Token = token, RefreshToken = refreshToken });
    }

    [HttpPost("google")]
    public async Task<IActionResult> GoogleAuth([FromBody] GoogleAuthRequest request)
    {
        var (succeeded, token, refreshToken, role, error) = await _identityService.SocialLoginOrRegisterAsync(
            request.IdToken,
            request.Email,
            request.FirstName,
            request.LastName,
            request.Role);

        if (!succeeded)
        {
            SentrySdk.CaptureMessage($"Google Auth failed for {request.Email ?? "Unknown"}: {error}", SentryLevel.Warning);
            return BadRequest(new { Error = error });
        }

        return Ok(new { Token = token, RefreshToken = refreshToken, Role = role });
    }
}
