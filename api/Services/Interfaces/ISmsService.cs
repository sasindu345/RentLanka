using System.Threading.Tasks;

namespace RentLanka.Api.Services.Interfaces;

public interface ISmsService
{
    Task SendSmsAsync(string toPhoneNumber, string message);
}
