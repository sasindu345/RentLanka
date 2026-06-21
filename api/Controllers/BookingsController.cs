using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RentLanka.Api.Models.Requests;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class BookingsController : AuthorizedControllerBase
{
    private readonly IBookingService _bookingService;

    public BookingsController(IBookingService bookingService)
    {
        _bookingService = bookingService;
    }

    [HttpPost]
    public async Task<IActionResult> CreateBooking([FromBody] BookingRequest request)
    {
        var (succeeded, booking, error) = await _bookingService.CreateBookingAsync(GetUserId(), request);
        if (!succeeded)
        {
            return BadRequest(new { Error = error });
        }

        return CreatedAtAction(nameof(GetBookingById), new { id = booking!.Id }, booking);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetBookingById(Guid id)
    {
        var booking = await _bookingService.GetBookingByIdAsync(id, GetUserId());
        if (booking == null)
        {
            return NotFound(new { Error = "Booking not found or unauthorized." });
        }

        return Ok(booking);
    }

    [HttpGet("renter")]
    public async Task<IActionResult> GetRenterBookings()
    {
        var bookings = await _bookingService.GetRenterBookingsAsync(GetUserId());
        return Ok(bookings);
    }

    [HttpGet("owner")]
    public async Task<IActionResult> GetOwnerBookings()
    {
        var bookings = await _bookingService.GetOwnerBookingsAsync(GetUserId());
        return Ok(bookings);
    }

    [HttpPatch("{id:guid}/approve")]
    public async Task<IActionResult> ApproveBooking(Guid id)
    {
        var (succeeded, error) = await _bookingService.ApproveBookingAsync(GetUserId(), id);
        if (!succeeded)
        {
            return error == "Unauthorized" ? Forbid() : BadRequest(new { Error = error });
        }

        return NoContent();
    }

    [HttpPatch("{id:guid}/reject")]
    public async Task<IActionResult> RejectBooking(Guid id)
    {
        var (succeeded, error) = await _bookingService.RejectBookingAsync(GetUserId(), id);
        if (!succeeded)
        {
            return error == "Unauthorized" ? Forbid() : BadRequest(new { Error = error });
        }

        return NoContent();
    }

    [HttpPatch("{id:guid}/pay")]
    public async Task<IActionResult> PayBooking(Guid id)
    {
        var (succeeded, error) = await _bookingService.PayBookingAsync(GetUserId(), id);
        if (!succeeded)
        {
            return error == "Unauthorized" ? Forbid() : BadRequest(new { Error = error });
        }

        return NoContent();
    }

    [HttpPatch("{id:guid}/handover")]
    public async Task<IActionResult> HandoverBooking(Guid id)
    {
        var (succeeded, error) = await _bookingService.HandoverBookingAsync(GetUserId(), id);
        if (!succeeded)
        {
            return error == "Unauthorized" ? Forbid() : BadRequest(new { Error = error });
        }

        return NoContent();
    }

    [HttpPatch("{id:guid}/return")]
    public async Task<IActionResult> ReturnBooking(Guid id)
    {
        var (succeeded, error) = await _bookingService.ReturnBookingAsync(GetUserId(), id);
        if (!succeeded)
        {
            return error == "Unauthorized" ? Forbid() : BadRequest(new { Error = error });
        }

        return NoContent();
    }
}
