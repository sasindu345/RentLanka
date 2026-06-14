using System;
using System.Security.Claims;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using RentLanka.Application.Common.Interfaces;

namespace RentLanka.Api.Endpoints;

public static class VerificationEndpoints
{
    public static void MapVerificationEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/verification").RequireAuthorization();

        group.MapPost("/send-email-token", async (ClaimsPrincipal user, IVerificationService verificationService) =>
        {
            var userId = GetUserId(user);
            var token = await verificationService.GenerateEmailVerificationTokenAsync(userId);
            
            // Console simulation
            Console.WriteLine($"[EMAIL GATEWAY SIMULATION] Sending verification token {token} to user {userId}");
            
            return Results.Ok(new { Message = "Email verification token generated." });
        });

        group.MapPost("/verify-email", async (VerifyEmailRequest request, ClaimsPrincipal user, IVerificationService verificationService) =>
        {
            var userId = GetUserId(user);
            var success = await verificationService.VerifyEmailAsync(userId, request.Token);

            if (!success)
            {
                return Results.BadRequest(new { Error = "Invalid or expired token." });
            }

            return Results.Ok(new { Message = "Email verified successfully." });
        });

        group.MapPost("/send-sms-otp", async (SendSmsOtpRequest request, ClaimsPrincipal user, IVerificationService verificationService) =>
        {
            var userId = GetUserId(user);
            var success = await verificationService.SendSmsOtpAsync(userId, request.PhoneNumber);

            if (!success)
            {
                return Results.BadRequest(new { Error = "Failed to send SMS OTP." });
            }

            return Results.Ok(new { Message = "SMS OTP sent successfully." });
        });

        group.MapPost("/verify-sms-otp", async (VerifySmsOtpRequest request, ClaimsPrincipal user, IVerificationService verificationService) =>
        {
            var userId = GetUserId(user);
            var success = await verificationService.VerifySmsOtpAsync(userId, request.Code);

            if (!success)
            {
                return Results.BadRequest(new { Error = "Invalid or expired OTP code." });
            }

            return Results.Ok(new { Message = "Mobile number verified successfully." });
        });

        group.MapPost("/nic", async (VerifyNicRequest request, ClaimsPrincipal user, IVerificationService verificationService) =>
        {
            var userId = GetUserId(user);
            var success = await verificationService.SubmitNicVerificationAsync(userId, request.NicNumber, request.DocumentUrl);

            if (!success)
            {
                return Results.BadRequest(new { Error = "Failed to submit NIC verification." });
            }

            return Results.Ok(new { Message = "NIC verification details submitted successfully." });
        });

        group.MapPost("/face", async (VerifyFaceRequest request, ClaimsPrincipal user, IVerificationService verificationService) =>
        {
            var userId = GetUserId(user);
            var success = await verificationService.CompleteFaceVerificationAsync(userId, request.BiometricDataHash);

            if (!success)
            {
                return Results.BadRequest(new { Error = "Face verification failed." });
            }

            return Results.Ok(new { Message = "Face verification completed. User is now trusted." });
        });
    }

    private static Guid GetUserId(ClaimsPrincipal user)
    {
        var claimValue = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(claimValue))
        {
            throw new UnauthorizedAccessException("User is not authenticated.");
        }
        return Guid.Parse(claimValue);
    }
}

public record VerifyEmailRequest(string Token);
public record SendSmsOtpRequest(string PhoneNumber);
public record VerifySmsOtpRequest(string Code);
public record VerifyNicRequest(string NicNumber, string DocumentUrl);
public record VerifyFaceRequest(string BiometricDataHash);
