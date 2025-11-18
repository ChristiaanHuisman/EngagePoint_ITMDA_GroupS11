using BusinessVerification_Service.Api.Dtos;

namespace BusinessVerification_Service.Api.Interfaces.ServicesInterfaces
{
    // Include methods from the service
    public interface IBusinessVerificationService
    {
        Task<BusinessVerificationResponseDto> BusinessVerificationProcess(
            string authorizationToken);

        (ParsedDomainDto? ParsedEmailDomain, ParsedDomainDto? ParsedWebsiteDomain)
            GetDomainInfo(string emailAddress, string websiteAddress);
    }
}
