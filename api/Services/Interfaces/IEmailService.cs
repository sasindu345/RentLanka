using System.Threading.Tasks;

namespace RentLanka.Api.Services.Interfaces;

public interface IEmailService
{
    Task SendEmailAsync(string toEmail, string subject, string htmlContent);
}
