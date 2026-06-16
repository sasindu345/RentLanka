using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Hosting;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class VerificationController : ControllerBase
{
    private readonly IVerificationService _verificationService;
    private readonly IWebHostEnvironment _environment;

    public VerificationController(IVerificationService verificationService, IWebHostEnvironment environment)
    {
        _verificationService = verificationService;
        _environment = environment;
    }

    [HttpPost("send-email-token")]
    public async Task<IActionResult> SendEmailToken()
    {
        var userId = GetUserId();
        var token = await _verificationService.GenerateEmailVerificationTokenAsync(userId);

        if (_environment.IsDevelopment())
        {
            return Ok(new { Message = "Email verification token generated.", DevToken = token });
        }

        return Ok(new { Message = "Email verification token generated." });
    }

    [HttpPost("verify-email")]
    public async Task<IActionResult> VerifyEmail([FromBody] VerifyEmailRequest request)
    {
        var userId = GetUserId();
        var success = await _verificationService.VerifyEmailAsync(userId, request.Token);

        if (!success)
        {
            return BadRequest(new { Error = "Invalid or expired token." });
        }

        return Ok(new { Message = "Email verified successfully." });
    }

    [HttpPost("send-sms-otp")]
    public async Task<IActionResult> SendSmsOtp([FromBody] SendSmsOtpRequest request)
    {
        var userId = GetUserId();
        var otp = await _verificationService.SendSmsOtpAsync(userId, request.PhoneNumber);

        if (_environment.IsDevelopment())
        {
            return Ok(new { Message = "SMS OTP sent successfully.", DevOtp = otp });
        }

        return Ok(new { Message = "SMS OTP sent successfully." });
    }

    [HttpPost("verify-sms-otp")]
    public async Task<IActionResult> VerifySmsOtp([FromBody] VerifySmsOtpRequest request)
    {
        var userId = GetUserId();
        var success = await _verificationService.VerifySmsOtpAsync(userId, request.Code);

        if (!success)
        {
            return BadRequest(new { Error = "Invalid or expired OTP code." });
        }

        return Ok(new { Message = "Mobile number verified successfully." });
    }

    [HttpPost("nic")]
    public async Task<IActionResult> VerifyNic([FromBody] VerifyNicRequest request)
    {
        var userId = GetUserId();
        var success = await _verificationService.SubmitNicVerificationAsync(userId, request.NicNumber, request.DocumentUrl);

        if (!success)
        {
            return BadRequest(new { Error = "Failed to submit NIC verification." });
        }

        return Ok(new { Message = "NIC verification details submitted successfully." });
    }

    [HttpPost("face")]
    public async Task<IActionResult> VerifyFace([FromBody] VerifyFaceRequest request)
    {
        var userId = GetUserId();
        var success = await _verificationService.CompleteFaceVerificationAsync(userId, request.BiometricDataHash);

        if (!success)
        {
            return BadRequest(new { Error = "Face verification failed." });
        }

        return Ok(new { Message = "Face verification completed. User is now trusted." });
    }

    private Guid GetUserId()
    {
        var claimValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(claimValue))
        {
            throw new UnauthorizedAccessException("User is not authenticated.");
        }
        return Guid.Parse(claimValue);
    }
}
