using System;
using System.Net;
using System.Net.Http;
using System.Net.Mail;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;
    private readonly HttpClient _httpClient;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger, HttpClient httpClient)
    {
        _configuration = configuration;
        _logger = logger;
        _httpClient = httpClient;
    }

    public async Task SendEmailAsync(string toEmail, string subject, string htmlContent)
    {
        var provider = _configuration["EmailSettings:Provider"] ?? "Console";
        var fromEmail = _configuration["EmailSettings:FromEmail"] ?? "noreply@rentlanka.lk";
        var fromName = _configuration["EmailSettings:FromName"] ?? "RentLanka Support";

        if (string.Equals(provider, "Console", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogInformation(
                "[EMAIL LOG ONLY]\nTo: {ToEmail}\nFrom: {FromName} <{FromEmail}>\nSubject: {Subject}\nContent:\n{Content}",
                toEmail, fromName, fromEmail, subject, htmlContent);
            return;
        }

        if (string.Equals(provider, "SendGrid", StringComparison.OrdinalIgnoreCase))
        {
            await SendViaSendGridAsync(toEmail, subject, htmlContent, fromEmail, fromName);
            return;
        }

        if (string.Equals(provider, "Smtp", StringComparison.OrdinalIgnoreCase))
        {
            await SendViaSmtpAsync(toEmail, subject, htmlContent, fromEmail, fromName);
            return;
        }

        _logger.LogWarning("Unknown email provider '{Provider}'. Defaulting to console logging.", provider);
        _logger.LogInformation(
            "[EMAIL LOG ONLY (FALLBACK)]\nTo: {ToEmail}\nSubject: {Subject}\nContent:\n{Content}",
            toEmail, subject, htmlContent);
    }

    private async Task SendViaSmtpAsync(string toEmail, string subject, string htmlContent, string fromEmail, string fromName)
    {
        var host = _configuration["EmailSettings:SmtpHost"];
        var portStr = _configuration["EmailSettings:SmtpPort"] ?? "587";
        var user = _configuration["EmailSettings:SmtpUser"];
        var pass = _configuration["EmailSettings:SmtpPass"];
        var sslStr = _configuration["EmailSettings:EnableSsl"] ?? "true";

        if (string.IsNullOrEmpty(host))
        {
            throw new InvalidOperationException("SMTP host is not configured.");
        }

        int.TryParse(portStr, out var port);
        bool.TryParse(sslStr, out var enableSsl);

        using var client = new SmtpClient(host, port)
        {
            EnableSsl = enableSsl,
            DeliveryMethod = SmtpDeliveryMethod.Network,
            UseDefaultCredentials = false
        };

        if (!string.IsNullOrEmpty(user) && !string.IsNullOrEmpty(pass))
        {
            client.Credentials = new NetworkCredential(user, pass);
        }

        var mailMessage = new MailMessage
        {
            From = new MailAddress(fromEmail, fromName),
            Subject = subject,
            Body = htmlContent,
            IsBodyHtml = true
        };
        mailMessage.To.Add(toEmail);

        try
        {
            _logger.LogInformation("Sending email to {ToEmail} via SMTP ({Host}:{Port})...", toEmail, host, port);
            await client.SendMailAsync(mailMessage);
            _logger.LogInformation("Email sent successfully to {ToEmail}.", toEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email to {ToEmail} via SMTP.", toEmail);
            throw;
        }
    }

    private async Task SendViaSendGridAsync(string toEmail, string subject, string htmlContent, string fromEmail, string fromName)
    {
        var apiKey = _configuration["EmailSettings:ApiKey"];
        if (string.IsNullOrEmpty(apiKey))
        {
            throw new InvalidOperationException("SendGrid ApiKey is not configured.");
        }

        var payload = new
        {
            personalizations = new[]
            {
                new { to = new[] { new { email = toEmail } } }
            },
            from = new { email = fromEmail, name = fromName },
            subject = subject,
            content = new[]
            {
                new { type = "text/html", value = htmlContent }
            }
        };

        var request = new HttpRequestMessage(HttpMethod.Post, "https://api.sendgrid.com/v3/mail/send");
        request.Headers.Add("Authorization", $"Bearer {apiKey}");
        request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

        try
        {
            _logger.LogInformation("Sending email to {ToEmail} via SendGrid API...", toEmail);
            var response = await _httpClient.SendAsync(request);
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync();
                throw new HttpRequestException($"SendGrid returned status {response.StatusCode}: {body}");
            }
            _logger.LogInformation("Email sent successfully to {ToEmail} via SendGrid.", toEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email to {ToEmail} via SendGrid API.", toEmail);
            throw;
        }
    }
}
