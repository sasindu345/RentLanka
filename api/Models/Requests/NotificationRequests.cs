using System.ComponentModel.DataAnnotations;

namespace RentLanka.Api.Models.Requests;

public class RegisterDeviceTokenRequest
{
    [Required]
    public string Token { get; set; } = string.Empty;

    [Required]
    public string Platform { get; set; } = string.Empty; // e.g. "Android", "iOS"
}
