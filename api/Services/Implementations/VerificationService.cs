using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RentLanka.Api.Data;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class VerificationService : IVerificationService
{
    private readonly AppDbContext _context;
    
    // In-memory cache for demo/development OTP and verification tokens
    private static readonly ConcurrentDictionary<Guid, (string Code, DateTime Expiry)> SmsOtps = new();
    private static readonly ConcurrentDictionary<Guid, (string Token, DateTime Expiry)> EmailTokens = new();

    public VerificationService(AppDbContext context)
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

    public Task<bool> SendSmsOtpAsync(Guid userId, string phoneNumber)
    {
        var random = new Random();
        var otp = random.Next(100000, 999999).ToString();
        
        SmsOtps[userId] = (otp, DateTime.UtcNow.AddMinutes(10));
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
