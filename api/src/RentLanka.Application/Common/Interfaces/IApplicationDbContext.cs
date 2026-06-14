using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RentLanka.Domain.Entities;

namespace RentLanka.Application.Common.Interfaces;

public interface IApplicationDbContext
{
    DbSet<User> Users { get; }
    
    Task<int> SaveChangesAsync(CancellationToken cancellationToken);
}
