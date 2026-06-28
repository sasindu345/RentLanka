using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using RentLanka.Api.Models.DTOs;
using RentLanka.Api.Models.Requests;

namespace RentLanka.Api.Services.Interfaces;

public interface IReviewService
{
    Task<ReviewResponse> CreateReviewAsync(Guid bookingId, Guid reviewerId, CreateReviewRequest request);
    Task<List<ReviewResponse>> GetReviewsByTargetUserAsync(Guid userId);
    Task<List<ReviewResponse>> GetReviewsByListingAsync(Guid listingId);
    Task<List<ReviewResponse>> GetReviewsByBookingAsync(Guid bookingId);
    Task<double> GetAverageUserRatingAsync(Guid userId);
    Task<double> GetAverageListingRatingAsync(Guid listingId);
}
