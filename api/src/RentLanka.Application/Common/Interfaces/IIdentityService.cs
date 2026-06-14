using System;
using System.Threading.Tasks;

namespace RentLanka.Application.Common.Interfaces;

public interface IIdentityService
{
    Task<(bool Succeeded, Guid UserId, string? Error)> CreateUserAsync(
        string email, 
        string password, 
        string firstName, 
        string lastName, 
        string phoneNumber);

    Task<(bool Succeeded, string? Token, string? Error)> LoginAsync(
        string email, 
        string password);
}
