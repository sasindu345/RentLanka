using System;
using System.Threading.Tasks;

namespace RentLanka.Application.Common.Interfaces;

public interface IVerificationService
{
    Task<string> GenerateEmailVerificationTokenAsync(Guid userId);
    Task<bool> VerifyEmailAsync(Guid userId, string token);
    
    Task<bool> SendSmsOtpAsync(Guid userId, string phoneNumber);
    Task<bool> VerifySmsOtpAsync(Guid userId, string code);

    Task<bool> SubmitNicVerificationAsync(Guid userId, string nicNumber, string documentUrl);
    Task<bool> CompleteFaceVerificationAsync(Guid userId, string biometricDataHash);
}
public record VerificationStatusDto(
    Guid UserId,
    int VerificationLevel,
    bool EmailVerified,
    bool MobileVerified,
    bool NicVerified,
    bool FaceVerified
);
