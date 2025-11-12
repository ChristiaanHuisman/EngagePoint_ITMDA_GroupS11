namespace BusinessVerification_Service.Api.Interfaces.HelpersInterfaces
{
    // Include methods from the helper
    public interface IWebsiteAddressHelper
    {
        bool VerifyWebsiteAddressScheme(string websiteAddress);

        string BuildUriWebsiteAddress(string websiteAddress);
    }
}
