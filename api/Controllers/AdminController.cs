using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[Authorize(Roles = "Admin")]
[ApiController]
[Route("api/admin")]
public class AdminController : ControllerBase
{
    private readonly IAdminService _adminService;
    private readonly IBookingService _bookingService;
    private readonly IEarningsService _earningsService;
    private readonly IDisputeService _disputeService;

    public AdminController(
        IAdminService adminService,
        IBookingService bookingService,
        IEarningsService earningsService,
        IDisputeService disputeService)
    {
        _adminService = adminService;
        _bookingService = bookingService;
        _earningsService = earningsService;
        _disputeService = disputeService;
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboardStats()
    {
        var stats = await _adminService.GetDashboardStatsAsync();
        return Ok(stats);
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetUsers(
        [FromQuery] string? query,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _adminService.GetUsersAsync(query, page, pageSize);
        return Ok(result);
    }

    [HttpGet("users/{id:guid}")]
    public async Task<IActionResult> GetUserById(Guid id)
    {
        var user = await _adminService.GetUserByIdAsync(id);
        if (user == null)
        {
            return NotFound(new { Error = "User not found." });
        }
        return Ok(user);
    }

    [HttpPatch("users/{id:guid}/ban")]
    public async Task<IActionResult> ToggleUserBan(Guid id)
    {
        var success = await _adminService.ToggleUserBanAsync(id);
        if (!success)
        {
            return BadRequest(new { Error = "Failed to toggle ban. User might not exist or is an Administrator." });
        }
        return Ok(new { Message = "User ban status toggled successfully." });
    }

    [HttpPatch("users/{id:guid}/verify-override")]
    public async Task<IActionResult> OverrideVerification(Guid id, [FromBody] OverrideVerificationRequest request)
    {
        var success = await _adminService.OverrideUserVerificationAsync(id, request.Level, request.IsTrusted);
        if (!success)
        {
            return BadRequest(new { Error = "Failed to override verification status." });
        }
        return Ok(new { Message = "Verification status overridden successfully." });
    }

    [HttpGet("listings")]
    public async Task<IActionResult> GetListings(
        [FromQuery] string? query,
        [FromQuery] bool? isPaused,
        [FromQuery] bool? isDeleted,
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _adminService.GetListingsAsync(query, isPaused, isDeleted, status, page, pageSize);
        return Ok(result);
    }

    [HttpPatch("listings/{id:guid}/pause")]
    public async Task<IActionResult> ToggleListingPause(Guid id)
    {
        var success = await _adminService.ToggleListingPauseAsync(id);
        if (!success)
        {
            return NotFound(new { Error = "Listing not found or already deleted." });
        }
        return Ok(new { Message = "Listing pause status toggled successfully." });
    }

    [HttpDelete("listings/{id:guid}")]
    public async Task<IActionResult> DeleteListing(Guid id)
    {
        var success = await _adminService.DeleteListingAsync(id);
        if (!success)
        {
            return NotFound(new { Error = "Listing not found or already deleted." });
        }
        return NoContent();
    }

    [HttpPatch("listings/{id:guid}/approve")]
    public async Task<IActionResult> ApproveListing(Guid id)
    {
        var success = await _adminService.ApproveListingAsync(id);
        if (!success)
        {
            return NotFound(new { Error = "Listing not found or already deleted." });
        }
        return Ok(new { Message = "Listing approved successfully." });
    }

    [HttpPatch("listings/{id:guid}/reject")]
    public async Task<IActionResult> RejectListing(Guid id)
    {
        var success = await _adminService.RejectListingAsync(id);
        if (!success)
        {
            return NotFound(new { Error = "Listing not found or already deleted." });
        }
        return Ok(new { Message = "Listing rejected successfully." });
    }

    [HttpGet("kyc")]
    public async Task<IActionResult> GetKycQueue()
    {
        var result = await _adminService.GetKycQueueAsync();
        return Ok(result);
    }

    [HttpPatch("kyc/{id:guid}/approve")]
    public async Task<IActionResult> ApproveKyc(Guid id)
    {
        var success = await _adminService.ApproveKycAsync(id);
        if (!success)
        {
            return BadRequest(new { Error = "Failed to approve KYC. Check if user is in Level 2 (NIC Submitted)." });
        }
        return Ok(new { Message = "KYC approved successfully." });
    }

    [HttpPatch("kyc/{id:guid}/reject")]
    public async Task<IActionResult> RejectKyc(Guid id)
    {
        var success = await _adminService.RejectKycAsync(id);
        if (!success)
        {
            return BadRequest(new { Error = "Failed to reject KYC. Check if user is in Level 2 (NIC Submitted)." });
        }
        return Ok(new { Message = "KYC rejected successfully." });
    }

    [HttpGet("bookings")]
    public async Task<IActionResult> GetAllBookings()
    {
        var bookings = await _bookingService.GetAllBookingsAsync();
        return Ok(bookings);
    }

    [HttpGet("payments")]
    public async Task<IActionResult> GetAllPayments()
    {
        var payments = await _earningsService.GetAllPaymentsAsync();
        return Ok(payments);
    }

    [HttpGet("payouts")]
    public async Task<IActionResult> GetAllPayouts()
    {
        var payouts = await _earningsService.GetAllPayoutsAsync();
        return Ok(payouts);
    }

    [HttpPatch("payouts/{id:guid}/approve")]
    public async Task<IActionResult> ApprovePayout(Guid id)
    {
        var (succeeded, error) = await _earningsService.ApprovePayoutAsync(id);
        if (!succeeded)
        {
            return BadRequest(new { Error = error });
        }
        return Ok(new { Message = "Payout approved successfully." });
    }

    [HttpGet("disputes")]
    public async Task<IActionResult> GetDisputes()
    {
        var disputes = await _disputeService.GetAdminDisputesAsync();
        return Ok(disputes);
    }

    [HttpPatch("disputes/{id:guid}/resolve")]
    public async Task<IActionResult> ResolveDispute(Guid id, [FromBody] ResolveDisputeRequest request)
    {
        try
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
            if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var adminId))
            {
                return Unauthorized();
            }

            var response = await _disputeService.ResolveDisputeAsync(id, adminId, request);
            return Ok(response);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { Error = ex.Message });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
        catch (Exception ex)
        {
            return BadRequest(new { Error = ex.Message });
        }
    }
}
