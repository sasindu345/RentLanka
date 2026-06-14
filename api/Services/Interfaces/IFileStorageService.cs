using System.IO;
using System.Threading.Tasks;

namespace RentLanka.Api.Services.Interfaces;

public interface IFileStorageService
{
    Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType);
    Task DeleteFileAsync(string fileUrl);
}
