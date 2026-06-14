using System;
using System.Collections.Concurrent;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RentLanka.Application.Common.Interfaces;
using RentLanka.Domain.Entities;
using RentLanka.Domain.Enums;

namespace RentLanka.Infrastructure.Verification;

public class VerificationService : IVerificationService
{
    private readonly IApplicationDbContext _context;
    
    // In-memory cache for demo/development OTP and verification tokens
    private static readonly ConcurrentDictionary<Guid, (string Code, DateTime Expiry)> SmsOtps = new();
    private static readonly ConcurrentDictionary<Guid, (string Token, DateTime Expiry)> EmailTokens = new();

    public VerificationService(IApplicationDbContext context)
    {
        _context = context;
    }

    public Task<string> GenerateEmailVerificationTokenAsync(Guid userId)
    {
        var token = Guid.NewGuid().ToString("N");
        EmailTokens[userId] = (token, DateTime.UtcNow.AddHours(24));
        return Task.FromResult(token);
    }

    public async Task<bool> VerifyEmailAsync(Guid userId, string token)
    {
        if (EmailTokens.TryGetValue(userId, out var cached) && cached.Token == token && cached.Expiry > DateTime.UtcNow)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user != null)
            {
                // Set to Level 0
                if (user.VerificationLevel < VerificationLevel.Level0)
                {
                    user.VerificationLevel = VerificationLevel.Level0;
                }
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync(CancellationToken.None);
                EmailTokens.TryRemove(userId, out _);
                return true;
            }
        }
        return false;
    }

    public Task<bool> SendSmsOtpAsync(Guid userId, string phoneNumber)
    {
        // Generate a standard 6 digit OTP
        var random = new Random();
        var otp = random.Next(100000, 999999).ToString();
        
        SmsOtps[userId] = (otp, DateTime.UtcNow.AddMinutes(10));
        
        // Console output simulation for SMS gateway
        Console.WriteLine($"[SMS GATEWAY SIMULATION] Sending OTP {otp} to {phoneNumber}");
        
        return Task.FromResult(true);
    }

    public async Task<bool> VerifySmsOtpAsync(Guid userId, string code)
    {
        if (SmsOtps.TryGetValue(userId, out var cached) && cached.Code == code && cached.Expiry > DateTime.UtcNow)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user != null)
            {
                // Progress to Level 1
                if (user.VerificationLevel < VerificationLevel.Level1)
                {
                    user.VerificationLevel = VerificationLevel.Level1;
                }
                user.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync(CancellationToken.None);
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
            // Progress to Level 2
            if (user.VerificationLevel < VerificationLevel.Level2)
            {
                user.VerificationLevel = VerificationLevel.Level2;
            }
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync(CancellationToken.None);
            return true;
        }
        return false;
    }

    public async Task<bool> CompleteFaceVerificationAsync(Guid userId, string biometricDataHash)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user != null)
        {
            // Progress to Level 3 (highest verification level)
            if (user.VerificationLevel < VerificationLevel.Level3)
            {
                user.VerificationLevel = VerificationLevel.Level3;
                user.IsTrustedUser = true; // Auto promote to trusted user on face verification for this MVP
            }
            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync(CancellationToken.None);
            return true;
        }
        return false;
    }
}
