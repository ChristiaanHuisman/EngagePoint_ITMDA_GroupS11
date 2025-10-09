namespace BusinessVerification_Service.Interfaces
{
    // Interface for dependency injection of the domain verification services
    public interface IDomainVerificationService
    {
        bool VerifyDomainMatch(string email, string website);
    }
}
