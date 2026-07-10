using System;
using System.Threading.Tasks;

namespace RentLanka.Api.Services.Interfaces;

public interface IVerificationService
{
    Task<string> GenerateEmailVerificationTokenAsync(Guid userId);
    Task<bool> VerifyEmailAsync(Guid userId, string token);
    
    Task<string> SendSmsOtpAsync(Guid userId, string phoneNumber);
    Task<bool> VerifySmsOtpAsync(Guid userId, string code);

    Task<bool> SubmitNicVerificationAsync(Guid userId, string nicNumber, string documentUrl);
    Task<bool> CompleteFaceVerificationAsync(Guid userId, string biometricDataHash);
    Task<bool> SubmitKycAsync(Guid userId, string nicNumber, string nicFrontUrl, string nicBackUrl, string faceCaptureUrl);
}

public record VerificationStatusDto(
    Guid UserId,
    int VerificationLevel,
    bool EmailVerified,
    bool MobileVerified,
    bool NicVerified,
    bool FaceVerified
);
