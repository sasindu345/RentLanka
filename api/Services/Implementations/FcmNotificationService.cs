using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RentLanka.Api.Data;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class FcmNotificationService : INotificationService
{
    private readonly IConfiguration _configuration;
    private readonly AppDbContext _dbContext;
    private readonly ILogger<FcmNotificationService> _logger;
    private readonly bool _useMockFallback;

    public FcmNotificationService(IConfiguration configuration, AppDbContext dbContext, ILogger<FcmNotificationService> logger)
    {
        _configuration = configuration;
        _dbContext = dbContext;
        _logger = logger;

        if (FirebaseApp.DefaultInstance == null)
        {
            var credentialPath = _configuration["FirebaseSettings:CredentialFilePath"];
            if (string.IsNullOrEmpty(credentialPath))
            {
                _logger.LogWarning("FirebaseSettings:CredentialFilePath is not configured. Running in Mock/Console notification mode.");
                _useMockFallback = true;
            }
            else
            {
                var fullPath = Path.Combine(AppContext.BaseDirectory, credentialPath);
                if (!File.Exists(fullPath))
                {
                    fullPath = credentialPath;
                }

                if (!File.Exists(fullPath))
                {
                    _logger.LogWarning($"Firebase credential file not found at '{credentialPath}' or '{fullPath}'. Running in Mock/Console notification mode.");
                    _useMockFallback = true;
                }
                else
                {
                    try
                    {
#pragma warning disable CS0618
                        FirebaseApp.Create(new AppOptions
                        {
                            Credential = GoogleCredential.FromFile(fullPath)
                        });
#pragma warning restore CS0618
                        _logger.LogInformation("Firebase Admin SDK successfully initialized.");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to initialize Firebase Admin SDK. Falling back to Mock/Console notification mode.");
                        _useMockFallback = true;
                    }
                }
            }
        }
        else
        {
            _logger.LogInformation("Firebase Admin SDK already initialized.");
        }
    }

    public async Task SendNotificationToUserAsync(Guid userId, string title, string body, Dictionary<string, string>? data = null)
    {
        var tokens = await _dbContext.DeviceTokens
            .Where(dt => dt.UserId == userId)
            .Select(dt => dt.Token)
            .ToListAsync();

        if (tokens.Count == 0)
        {
            _logger.LogInformation($"No registered device tokens found for User {userId}.");
            PrintToConsole(userId.ToString(), title, body, data);
            return;
        }

        if (_useMockFallback || FirebaseApp.DefaultInstance == null)
        {
            _logger.LogInformation($"[MOCK PUSH] Sending notifications to User {userId} ({tokens.Count} devices)");
            PrintToConsole(userId.ToString(), title, body, data);
            return;
        }

        try
        {
            var message = new MulticastMessage
            {
                Tokens = tokens,
                Notification = new Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data
            };

            var response = await FirebaseMessaging.DefaultInstance.SendEachForMulticastAsync(message);
            _logger.LogInformation($"FCM Multicast successfully sent to User {userId}. Successes: {response.SuccessCount}, Failures: {response.FailureCount}");
            
            if (response.FailureCount > 0)
            {
                var tokensToRemove = new List<string>();
                for (int i = 0; i < response.Responses.Count; i++)
                {
                    if (!response.Responses[i].IsSuccess)
                    {
                        tokensToRemove.Add(tokens[i]);
                    }
                }

                if (tokensToRemove.Count > 0)
                {
                    var dbTokens = await _dbContext.DeviceTokens
                        .Where(dt => tokensToRemove.Contains(dt.Token))
                        .ToListAsync();
                    _dbContext.DeviceTokens.RemoveRange(dbTokens);
                    await _dbContext.SaveChangesAsync();
                    _logger.LogInformation($"Cleaned up {dbTokens.Count} expired/invalid device tokens from database.");
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error sending FCM push to User {userId}.");
        }
    }

    public async Task SendNotificationToDeviceAsync(string token, string title, string body, Dictionary<string, string>? data = null)
    {
        if (_useMockFallback || FirebaseApp.DefaultInstance == null)
        {
            _logger.LogInformation($"[MOCK PUSH] Sending notification to device token: {token}");
            PrintToConsole(token, title, body, data);
            return;
        }

        try
        {
            var message = new Message
            {
                Token = token,
                Notification = new Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data
            };

            var response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
            _logger.LogInformation($"FCM push successfully sent to token. MessageID: {response}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error sending FCM push to device token: {token}.");
        }
    }

    private void PrintToConsole(string recipient, string title, string body, Dictionary<string, string>? data)
    {
        Console.WriteLine("\n========================================================");
        Console.WriteLine($"🔔 [PUSH NOTIFICATION] Target: {recipient}");
        Console.WriteLine($"👉 Title: {title}");
        Console.WriteLine($"👉 Body: {body}");
        if (data != null && data.Count > 0)
        {
            Console.WriteLine("👉 Data:");
            foreach (var kvp in data)
            {
                Console.WriteLine($"   - {kvp.Key}: {kvp.Value}");
            }
        }
        Console.WriteLine("========================================================\n");
    }
}
