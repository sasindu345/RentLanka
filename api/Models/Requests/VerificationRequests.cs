namespace RentLanka.Api.Models.Requests;

public record VerifyEmailRequest(string Token);

public record SendSmsOtpRequest(string PhoneNumber);

public record VerifySmsOtpRequest(string Code);

public record VerifyNicRequest(string NicNumber, string DocumentUrl);

public record VerifyFaceRequest(string BiometricDataHash);

public record SubmitKycRequest(
    string NicNumber,
    string NicFrontUrl,
    string NicBackUrl,
    string FaceCaptureUrl
);

public record RejectKycRequest(string Reason);
