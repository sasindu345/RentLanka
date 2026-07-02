using System;
using System.IO;
using System.Threading.Tasks;
using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using RentLanka.Api.Services.Interfaces;

namespace RentLanka.Api.Services.Implementations;

public class CloudinaryFileStorageService : IFileStorageService
{
    private readonly IConfiguration _configuration;
    private readonly Cloudinary? _cloudinary;
    private readonly bool _useLocalFallback;
    private readonly string _localUploadPath;

    public CloudinaryFileStorageService(IConfiguration configuration, IWebHostEnvironment environment)
    {
        _configuration = configuration;
        var cloudName = _configuration["FileStorageSettings:CloudName"];
        var apiKey = _configuration["FileStorageSettings:ApiKey"];
        var apiSecret = _configuration["FileStorageSettings:ApiSecret"];
        var provider = _configuration["FileStorageSettings:Provider"] ?? "Local";

        var webRoot = environment.WebRootPath ?? Path.Combine(environment.ContentRootPath, "wwwroot");
        _localUploadPath = Path.Combine(webRoot, "uploads");

        if (provider.Equals("Local", StringComparison.OrdinalIgnoreCase) ||
            string.IsNullOrEmpty(cloudName) || 
            string.IsNullOrEmpty(apiKey) || 
            string.IsNullOrEmpty(apiSecret))
        {
            _useLocalFallback = true;
            if (!Directory.Exists(_localUploadPath))
            {
                Directory.CreateDirectory(_localUploadPath);
            }
        }
        else
        {
            var account = new Account(cloudName, apiKey, apiSecret);
            _cloudinary = new Cloudinary(account);
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

        if (_cloudinary == null)
        {
            throw new InvalidOperationException("Cloudinary client is not initialized.");
        }

        var uploadParams = new ImageUploadParams
        {
            File = new FileDescription(uniqueFileName, fileStream),
            Folder = "rentlanka",
            UseFilename = true,
            UniqueFilename = true
        };

        var uploadResult = await _cloudinary.UploadAsync(uploadParams);
        if (uploadResult.Error != null)
        {
            throw new Exception($"Cloudinary upload failed: {uploadResult.Error.Message}");
        }

        return uploadResult.SecureUrl.ToString();
    }

    public async Task DeleteFileAsync(string fileUrl)
    {
        if (string.IsNullOrEmpty(fileUrl))
        {
            return;
        }

        if (_useLocalFallback || fileUrl.StartsWith("/uploads/"))
        {
            var fileName = Path.GetFileName(fileUrl);
            var filePath = Path.Combine(_localUploadPath, fileName);
            if (File.Exists(filePath))
            {
                File.Delete(filePath);
            }
            return;
        }

        if (_cloudinary == null)
        {
            throw new InvalidOperationException("Cloudinary client is not initialized.");
        }

        var publicId = GetPublicIdFromUrl(fileUrl);
        var deletionParams = new DeletionParams(publicId);
        var deletionResult = await _cloudinary.DestroyAsync(deletionParams);
        if (deletionResult.Error != null)
        {
            throw new Exception($"Cloudinary deletion failed: {deletionResult.Error.Message}");
        }
    }

    private string GetPublicIdFromUrl(string fileUrl)
    {
        try
        {
            var uri = new Uri(fileUrl);
            var segments = uri.Segments;
            
            int uploadIndex = -1;
            for (int i = 0; i < segments.Length; i++)
            {
                if (segments[i].Equals("upload/", StringComparison.OrdinalIgnoreCase))
                {
                    uploadIndex = i;
                    break;
                }
            }

            if (uploadIndex != -1 && uploadIndex < segments.Length - 1)
            {
                int startSegment = uploadIndex + 1;
                // Skip version number (e.g. v123456789)
                if (segments[startSegment].StartsWith("v") && segments[startSegment].Length > 1 && char.IsDigit(segments[startSegment][1]))
                {
                    startSegment++;
                }

                var publicIdPath = string.Join("", segments, startSegment, segments.Length - startSegment);
                var extension = Path.GetExtension(publicIdPath);
                if (!string.IsNullOrEmpty(extension))
                {
                    publicIdPath = publicIdPath.Substring(0, publicIdPath.Length - extension.Length);
                }
                
                return Uri.UnescapeDataString(publicIdPath);
            }
        }
        catch
        {
            return Path.GetFileNameWithoutExtension(fileUrl);
        }

        return Path.GetFileNameWithoutExtension(fileUrl);
    }
}
