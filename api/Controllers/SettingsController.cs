using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[ApiController]
[Route("api")]
public class SettingsController : ControllerBase
{
    private readonly ISettingsService _settingsService;

    public SettingsController(ISettingsService settingsService)
    {
        _settingsService = settingsService;
    }

    [HttpGet("settings")]
    public async Task<IActionResult> GetPublicSettings()
    {
        var settings = await _settingsService.GetSettingsAsync();
        try
        {
            var categories = JsonSerializer.Deserialize<List<string>>(settings.CategoriesJson) ?? new List<string>();
            return Ok(new { Categories = categories });
        }
        catch
        {
            return Ok(new { Categories = new List<string> { "Photography", "Tools", "Camping", "Electronics", "Sports", "Other" } });
        }
    }

    [Authorize(Roles = "Admin")]
    [HttpGet("admin/settings")]
    public async Task<IActionResult> GetAdminSettings()
    {
        var settings = await _settingsService.GetSettingsAsync();
        try
        {
            var categories = JsonSerializer.Deserialize<List<string>>(settings.CategoriesJson) ?? new List<string>();
            return Ok(new
            {
                settings.Id,
                settings.CommissionRate,
                Categories = categories,
                settings.UpdatedAt
            });
        }
        catch
        {
            return Ok(new
            {
                settings.Id,
                settings.CommissionRate,
                Categories = new List<string> { "Photography", "Tools", "Camping", "Electronics", "Sports", "Other" },
                settings.UpdatedAt
            });
        }
    }

    [Authorize(Roles = "Admin")]
    [HttpPut("admin/settings")]
    public async Task<IActionResult> UpdateSettings([FromBody] UpdateSettingsRequest request)
    {
        try
        {
            var settings = await _settingsService.UpdateSettingsAsync(request);
            var categories = JsonSerializer.Deserialize<List<string>>(settings.CategoriesJson) ?? new List<string>();
            return Ok(new
            {
                settings.Id,
                settings.CommissionRate,
                Categories = categories,
                settings.UpdatedAt
            });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Error = "An unexpected error occurred: " + ex.Message });
        }
    }
}
