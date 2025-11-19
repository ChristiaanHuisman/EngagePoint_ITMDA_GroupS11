using BusinessVerification_Service.Api.Dtos;
using BusinessVerification_Service.Api.Models;

namespace BusinessVerification_Service.Api.Interfaces.ServicesInterfaces
{
    // Include methods from the service
    public interface IEmailVerificationService
    {
        Task NewVerificationEmail(UserModel userModel, string userId);

        Task ResendVerificationEmail(EmailVerificationTokenModel oldTokenModel,
            string oldToken);

        Task SendVerificationEmailProcess(EmailVerificationTokenModel tokenModel);

        Task<BusinessVerificationResponseDto> VerifyEmailVerificaitonToken(
            string? verificationToken);
    }
}
