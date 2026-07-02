using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace RentLanka.Api.Services.Interfaces;

public interface INotificationService
{
    Task SendNotificationToUserAsync(Guid userId, string title, string body, Dictionary<string, string>? data = null);
    Task SendNotificationToDeviceAsync(string token, string title, string body, Dictionary<string, string>? data = null);
}
