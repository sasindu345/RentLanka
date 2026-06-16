using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/users")]
public class UsersController : AuthorizedControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetCurrentUser()
    {
        var user = await _userService.GetCurrentUserAsync(GetUserId());
        if (user == null)
        {
            return NotFound(new { Error = "User not found." });
        }

        return Ok(user);
    }

    [HttpPatch("me")]
    public async Task<IActionResult> UpdateCurrentUser([FromBody] UpdateUserRequest request)
    {
        var (succeeded, user, error) = await _userService.UpdateUserAsync(GetUserId(), request);
        if (!succeeded)
        {
            return BadRequest(new { Error = error });
        }

        return Ok(user);
    }

    [AllowAnonymous]
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetPublicProfile(Guid id)
    {
        var user = await _userService.GetPublicProfileAsync(id);
        if (user == null)
        {
            return NotFound(new { Error = "User not found." });
        }

        return Ok(user);
    }
}
