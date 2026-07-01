using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class SmsService : ISmsService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<SmsService> _logger;
    private readonly HttpClient _httpClient;

    public SmsService(IConfiguration configuration, ILogger<SmsService> logger, HttpClient httpClient)
    {
        _configuration = configuration;
        _logger = logger;
        _httpClient = httpClient;
    }

    public async Task SendSmsAsync(string toPhoneNumber, string message)
    {
        var provider = _configuration["SmsSettings:Provider"] ?? "Console";
        var fromNumber = _configuration["SmsSettings:FromNumber"];

        if (string.Equals(provider, "Console", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogInformation(
                "[SMS LOG ONLY]\nTo: {ToPhone}\nFrom: {FromPhone}\nMessage: {Message}",
                toPhoneNumber, fromNumber, message);
            return;
        }

        if (string.Equals(provider, "Twilio", StringComparison.OrdinalIgnoreCase))
        {
            await SendViaTwilioAsync(toPhoneNumber, message, fromNumber);
            return;
        }

        if (string.Equals(provider, "NotifyLk", StringComparison.OrdinalIgnoreCase))
        {
            await SendViaNotifyLkAsync(toPhoneNumber, message, fromNumber);
            return;
        }

        _logger.LogWarning("Unknown SMS provider '{Provider}'. Defaulting to console logging.", provider);
        _logger.LogInformation(
            "[SMS LOG ONLY (FALLBACK)]\nTo: {ToPhone}\nMessage: {Message}",
            toPhoneNumber, message);
    }

    private async Task SendViaTwilioAsync(string toPhoneNumber, string message, string? fromNumber)
    {
        var accountSid = _configuration["SmsSettings:AccountSid"];
        var authToken = _configuration["SmsSettings:ApiKey"]; // Using ApiKey as the Auth Token

        if (string.IsNullOrEmpty(accountSid) || string.IsNullOrEmpty(authToken) || string.IsNullOrEmpty(fromNumber))
        {
            throw new InvalidOperationException("Twilio configuration (AccountSid, ApiKey/AuthToken, FromNumber) is incomplete.");
        }

        var url = $"https://api.twilio.com/2010-04-01/Accounts/{accountSid}/Messages.json";
        var request = new HttpRequestMessage(HttpMethod.Post, url);

        var credentials = Convert.ToBase64String(Encoding.ASCII.GetBytes($"{accountSid}:{authToken}"));
        request.Headers.Authorization = new AuthenticationHeaderValue("Basic", credentials);

        var postData = new Dictionary<string, string>
        {
            { "To", toPhoneNumber },
            { "From", fromNumber },
            { "Body", message }
        };
        request.Content = new FormUrlEncodedContent(postData);

        _logger.LogInformation("Sending SMS to {ToPhone} via Twilio...", toPhoneNumber);
        var response = await _httpClient.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"Twilio returned status {response.StatusCode}: {body}");
        }
        _logger.LogInformation("SMS sent successfully to {ToPhone} via Twilio.", toPhoneNumber);
    }

    private async Task SendViaNotifyLkAsync(string toPhoneNumber, string message, string? senderId)
    {
        var userId = _configuration["SmsSettings:AccountSid"]; // Using AccountSid as the User ID
        var apiKey = _configuration["SmsSettings:ApiKey"];

        if (string.IsNullOrEmpty(userId) || string.IsNullOrEmpty(apiKey))
        {
            throw new InvalidOperationException("Notify.lk configuration (AccountSid/UserId, ApiKey) is incomplete.");
        }

        // Clean phone number: remove '+' prefix
        var cleanPhone = toPhoneNumber.Replace("+", "").Trim();

        var url = "https://app.notify.lk/api/v1/send";
        var requestUrl = $"{url}?user_id={userId}&api_key={apiKey}&sender_id={senderId ?? "NotifyDEMO"}&to={cleanPhone}&message={Uri.EscapeDataString(message)}";

        var request = new HttpRequestMessage(HttpMethod.Post, requestUrl);

        _logger.LogInformation("Sending SMS to {ToPhone} via Notify.lk...", toPhoneNumber);
        var response = await _httpClient.SendAsync(request);
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"Notify.lk returned status {response.StatusCode}: {body}");
        }
        _logger.LogInformation("SMS sent successfully to {ToPhone} via Notify.lk.", toPhoneNumber);
    }
}
