using System;
using System.IO;
using System.Threading.Tasks;
using Amazon.S3;
using Amazon.S3.Transfer;
using Microsoft.Extensions.Configuration;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class S3FileStorageService : IFileStorageService
{
    private readonly IConfiguration _configuration;
    private readonly IAmazonS3? _s3Client;
    private readonly string _bucketName = string.Empty;
    private readonly bool _useLocalFallback;
    private readonly string _localUploadPath;

    public S3FileStorageService(IConfiguration configuration)
    {
        _configuration = configuration;
        var accessKey = _configuration["AWS:AccessKey"];
        var secretKey = _configuration["AWS:SecretKey"];
        var region = _configuration["AWS:Region"] ?? "us-east-1";
        _bucketName = _configuration["AWS:BucketName"] ?? "rentlanka-uploads";

        _localUploadPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "wwwroot", "uploads");

        if (string.IsNullOrEmpty(accessKey) || string.IsNullOrEmpty(secretKey))
        {
            _useLocalFallback = true;
            if (!Directory.Exists(_localUploadPath))
            {
                Directory.CreateDirectory(_localUploadPath);
            }
        }
        else
        {
            var config = new AmazonS3Config
            {
                RegionEndpoint = Amazon.RegionEndpoint.GetBySystemName(region)
            };
            _s3Client = new AmazonS3Client(accessKey, secretKey, config);
        }
    }

    public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType)
    {
        var uniqueFileName = $"{Guid.NewGuid()}_{fileName}";

        if (_useLocalFallback)
        {
            var filePath = Path.Combine(_localUploadPath, uniqueFileName);
            using (var localStream = new FileStream(filePath, FileMode.Create))
            {
                await fileStream.CopyToAsync(localStream);
            }
            return $"/uploads/{uniqueFileName}";
        }

        if (_s3Client == null)
        {
            throw new InvalidOperationException("AWS S3 Client is not initialized.");
        }

        var fileTransferUtility = new TransferUtility(_s3Client);
        
        var uploadRequest = new TransferUtilityUploadRequest
        {
            InputStream = fileStream,
            Key = uniqueFileName,
            BucketName = _bucketName,
            ContentType = contentType
        };

        await fileTransferUtility.UploadAsync(uploadRequest);

        return $"https://{_bucketName}.s3.amazonaws.com/{uniqueFileName}";
    }

    public Task DeleteFileAsync(string fileUrl)
    {
        if (string.IsNullOrEmpty(fileUrl))
        {
            return Task.CompletedTask;
        }

        if (_useLocalFallback)
        {
            var fileName = Path.GetFileName(fileUrl);
            var filePath = Path.Combine(_localUploadPath, fileName);
            if (File.Exists(filePath))
            {
                File.Delete(filePath);
            }
            return Task.CompletedTask;
        }

        if (_s3Client == null)
        {
            throw new InvalidOperationException("AWS S3 Client is not initialized.");
        }

        var uri = new Uri(fileUrl);
        var key = uri.AbsolutePath.TrimStart('/');

        return _s3Client.DeleteObjectAsync(_bucketName, key);
    }
}
