using System.ComponentModel.DataAnnotations;

namespace RentLanka.Api.Models.Requests;

public record CreateReviewRequest(
    [Range(1, 5, ErrorMessage = "Rating must be between 1 and 5.")] int Rating,
    [MaxLength(2000, ErrorMessage = "Comment cannot exceed 2000 characters.")] string Comment
);
