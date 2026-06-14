using System;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using RentLanka.Application.Common.Interfaces;

namespace RentLanka.Api.Endpoints;

public static class FileEndpoints
{
    public static void MapFileEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/files").RequireAuthorization();

        group.MapPost("/avatar", async (IFormFile file, ClaimsPrincipal user, IFileStorageService fileStorage, IApplicationDbContext dbContext) =>
        {
            if (file == null || file.Length == 0)
            {
                return Results.BadRequest(new { Error = "No file uploaded." });
            }

            // Verify file is an image
            if (!file.ContentType.StartsWith("image/"))
            {
                return Results.BadRequest(new { Error = "Only image uploads are allowed." });
            }

            var userIdClaim = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdClaim))
            {
                return Results.Unauthorized();
            }

            var userId = Guid.Parse(userIdClaim);
            var dbUser = await dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (dbUser == null)
            {
                return Results.NotFound(new { Error = "User not found." });
            }

            // Delete old avatar if exists
            if (!string.IsNullOrEmpty(dbUser.AvatarUrl))
            {
                await fileStorage.DeleteFileAsync(dbUser.AvatarUrl);
            }

            // Upload new avatar
            using var stream = file.OpenReadStream();
            var avatarUrl = await fileStorage.UploadFileAsync(stream, file.FileName, file.ContentType);

            dbUser.AvatarUrl = avatarUrl;
            dbUser.UpdatedAt = DateTime.UtcNow;
            await dbContext.SaveChangesAsync(CancellationToken.None);

            return Results.Ok(new { AvatarUrl = avatarUrl, Message = "Avatar updated successfully." });
        }).DisableAntiforgery(); // Disable antiforgery verification for simple API upload in this development sprint
    }
}
