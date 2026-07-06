using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace RentLanka.Api.Models.Requests;

public record CreateListingRequest(
    [Required, MaxLength(32, ErrorMessage = "Title cannot exceed 32 characters.")] string Title,
    [Required] string Description,
    [Required] string Category,
    [Range(0.01, 1000000.0, ErrorMessage = "Price must be positive.")] decimal PricePerDay,
    [Range(0.0, 1000000.0, ErrorMessage = "Security deposit must be non-negative.")] decimal SecurityDeposit,
    string Rules,
    double Latitude,
    double Longitude,
    [Required] string District,
    List<string> Images);

public record UpdateListingRequest(
    [Required, MaxLength(32, ErrorMessage = "Title cannot exceed 32 characters.")] string Title,
    [Required] string Description,
    [Required] string Category,
    [Range(0.01, 1000000.0, ErrorMessage = "Price must be positive.")] decimal PricePerDay,
    [Range(0.0, 1000000.0, ErrorMessage = "Security deposit must be non-negative.")] decimal SecurityDeposit,
    string Rules,
    double Latitude,
    double Longitude,
    [Required] string District,
    List<string> Images);
