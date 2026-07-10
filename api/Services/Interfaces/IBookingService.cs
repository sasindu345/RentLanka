using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Requests;

namespace RentLanka.Api.Services.Interfaces;

public interface IBookingService
{
    Task<(bool Succeeded, BookingResponse? Booking, string? Error)> CreateBookingAsync(Guid renterId, BookingRequest request);
    Task<BookingResponse?> GetBookingByIdAsync(Guid bookingId, Guid userId);
    Task<IEnumerable<BookingResponse>> GetRenterBookingsAsync(Guid renterId);
    Task<IEnumerable<BookingResponse>> GetOwnerBookingsAsync(Guid ownerId);
    Task<(bool Succeeded, string? Error)> ApproveBookingAsync(Guid ownerId, Guid bookingId);
    Task<(bool Succeeded, string? Error)> RejectBookingAsync(Guid ownerId, Guid bookingId);
    Task<(bool Succeeded, string? Error)> PayBookingAsync(Guid renterId, Guid bookingId);
    Task<(bool Succeeded, string? Error)> HandoverBookingAsync(Guid callerId, Guid bookingId);
    Task<(bool Succeeded, string? Error)> ReturnBookingAsync(Guid ownerId, Guid bookingId);
    Task<IEnumerable<AvailabilityBlockResponse>> GetListingAvailabilityAsync(Guid listingId);
    Task<(bool Succeeded, string? Error)> CreateManualBlockAsync(Guid ownerId, Guid listingId, DateTime start, DateTime end);
    Task<(bool Succeeded, string? Error)> DeleteManualBlockAsync(Guid ownerId, Guid blockId);
    Task<IEnumerable<BookingResponse>> GetAllBookingsAsync();
}
