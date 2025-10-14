using BusinessVerification_Service.Dtos;

namespace BusinessVerification_Service.Interfaces
{
    // Interface for dependency injection of the domain verification services
    public interface IDomainVerificationService
    {
        VerificationResponseDto VerifyBusiness(string email, string website, string name)
    }
}
