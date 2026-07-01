using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using RentLanka.Api.Data;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class VerificationService : IVerificationService
{
    private readonly AppDbContext _context;
    private readonly ILogger<VerificationService> _logger;
    private readonly IEmailService _emailService;
    
    // In-memory cache for demo/development OTP and verification tokens
    private static readonly ConcurrentDictionary<Guid, (string Code, DateTime Expiry)> SmsOtps = new();
    private static readonly ConcurrentDictionary<Guid, (string Token, DateTime Expiry)> EmailTokens = new();

    public VerificationService(AppDbContext context, ILogger<VerificationService> logger, IEmailService emailService)
    {
        _context = context;
        _logger = logger;
        _emailService = emailService;
    }

    public async Task<string> GenerateEmailVerificationTokenAsync(Guid userId)
    {
        var token = Guid.NewGuid().ToString("N").Substring(0, 6).ToUpper();
        EmailTokens[userId] = (token, DateTime.UtcNow.AddHours(24));
        
        var user = await _context.Users.FindAsync(userId);
        if (user != null)
        {
            var subject = "Verify your RentLanka Email Address";
            var body = $@"
                <div style='font-family: sans-serif; padding: 24px; max-width: 600px; margin: auto; border: 1px solid #e2e8f0; border-radius: 12px;'>
                    <h2 style='color: #0d9488;'>Verify your Email Address</h2>
                    <p>Hi {user.FirstName},</p>
                    <p>Thank you for signing up for RentLanka. Please use the verification token below to verify your email address:</p>
                    <div style='background-color: #f1f5f9; padding: 16px; font-size: 24px; font-weight: bold; text-align: center; letter-spacing: 4px; color: #0f172a; margin: 24px 0; border-radius: 8px;'>
                        {token}
                    </div>
                    <p style='font-size: 12px; color: #64748b;'>This token is valid for 24 hours. If you did not request this verification, please ignore this email.</p>
                </div>";

            try
            {
                await _emailService.SendEmailAsync(user.Email, subject, body);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending verification email to {Email}", user.Email);
            }
        }
        else
        {
            _logger.LogWarning("User {UserId} not found. Cannot send verification email.", userId);
        }

        return token;
    }

    public async Task<bool> VerifyEmailAsync(Guid userId, string token)
    {
        if (EmailTokens.TryGetValue(userId, out var cached) && cached.Token == token && cached.Expiry > DateTime.UtcNow)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user != null)
            {
                if (user.VerificationLevel < VerificationLevel.Level0)
                {
                    user.VerificationLevel = VerificationLevel.Level0;
                }
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
                EmailTokens.TryRemove(userId, out _);
                return true;
            }
        }
        return false;
    }

    public Task<string> SendSmsOtpAsync(Guid userId, string phoneNumber)
    {
        var random = new Random();
        var otp = random.Next(100000, 999999).ToString();
        
        SmsOtps[userId] = (otp, DateTime.UtcNow.AddMinutes(10));
        _logger.LogInformation("[SMS GATEWAY SIMULATION] OTP {Otp} sent to {PhoneNumber} for user {UserId}", otp, phoneNumber, userId);
        
        return Task.FromResult(otp);
    }

    public async Task<bool> VerifySmsOtpAsync(Guid userId, string code)
    {
        if (SmsOtps.TryGetValue(userId, out var cached) && cached.Code == code && cached.Expiry > DateTime.UtcNow)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user != null)
            {
                if (user.VerificationLevel < VerificationLevel.Level1)
                {
                    user.VerificationLevel = VerificationLevel.Level1;
                }
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
                SmsOtps.TryRemove(userId, out _);
                return true;
            }
        }
        return false;
    }

    public async Task<bool> SubmitNicVerificationAsync(Guid userId, string nicNumber, string documentUrl)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user != null)
        {
            user.NICNumber = nicNumber;
            user.NicDocumentUrl = documentUrl;
            if (user.VerificationLevel < VerificationLevel.Level2)
            {
                user.VerificationLevel = VerificationLevel.Level2;
            }
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }
        return false;
    }

    public async Task<bool> CompleteFaceVerificationAsync(Guid userId, string biometricDataHash)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user != null)
        {
            if (user.VerificationLevel < VerificationLevel.Level3)
            {
                user.VerificationLevel = VerificationLevel.Level3;
                user.IsTrustedUser = true;
            }
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }
        return false;
    }
}
