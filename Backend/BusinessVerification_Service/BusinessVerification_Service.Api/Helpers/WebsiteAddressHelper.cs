using BusinessVerification_Service.Api.Interfaces.HelpersInterfaces;

namespace BusinessVerification_Service.Api.Helpers
{
    public class WebsiteAddressHelper : IWebsiteAddressHelper
    {
        // Return true if the website address has
        // a supported scheme, only has one scheme,
        // or does not have a scheme at all
        public bool VerifyWebsiteAddressScheme(string websiteAddress)
        {
            // Check is a scheme exists in the website address
            if (websiteAddress.Contains("://"))
            {
                // Count number of schemes in website address
                // There should not be more that 1 scheme
                int schemeCount = websiteAddress.Split("://").Length - 1;
                if (schemeCount > 1)
                {
                    return false;
                }

                // Get first part of website address before ://
                // Only http, https and ftp are supported schemes
                string scheme = websiteAddress.Split("://")[0];
                if (scheme != "http" && scheme != "https" && scheme != "ftp")
                {
                    return false;
                }
            }

            return true;
        }

        // Return a correctly built URI formatted website address
        public string BuildUriWebsiteAddress(string websiteAddress)
        {
            // Add https scheme if no scheme exists
            UriBuilder uriBuilder = new UriBuilder(
                websiteAddress.StartsWith("http", StringComparison.Ordinal)
                || websiteAddress.StartsWith("ftp", StringComparison.Ordinal)
                ? websiteAddress
                : $"https://{websiteAddress}"
            );

            return uriBuilder.Uri.ToString();
        }
    }
}
