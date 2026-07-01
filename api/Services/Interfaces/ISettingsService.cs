using System.Threading.Tasks;
using RentLanka.Api.Models.Entities;
using RentLanka.Api.Models.Requests;

namespace RentLanka.Api.Services.Interfaces;

public interface ISettingsService
{
    Task<PlatformSetting> GetSettingsAsync();
    Task<PlatformSetting> UpdateSettingsAsync(UpdateSettingsRequest request);
}
