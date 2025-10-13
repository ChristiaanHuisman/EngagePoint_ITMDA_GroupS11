using BusinessVerification_Service.Interfaces;
using Nager.PublicSuffix;
using System.Net.Mail;

namespace BusinessVerification_Service.Services
{
    public class DomainVerificationService : IDomainVerificationService
    {
        // Injected dependencies
        private readonly ILogger<DomainVerificationService> _logger;
        private readonly IDomainParser _domainParser;

        // Constructor for dependency injection of logger and domain parser
        public DomainVerificationService(ILogger<DomainVerificationService> logger, IDomainParser domainParser)
        {
            _logger = logger;
            _domainParser = domainParser;
        }

        // Verifies if the domain of the provided email matches the domain of the provided website
        // Returns true if they match, false and error messages otherwise
        public bool VerifyDomainMatch(string email, string website)
        {
            _logger.LogInformation(
                "Service: Domain verification for email {email} and website {website} started.",
                email, website
            );

            string errorMessageEnd = "Please ensure all details are entered correctly and try again, " +
                "contact support if the issue persists.";

            // Wrapper safety try block for the entire method
            try
            {
                // Handle empty input errors
                if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(website))
                {
                    _logger.LogWarning(
                        "Service: Empty email {email} or website {website}.", 
                        email, website
                    );
                    throw new ArgumentException("No email or website received. " + 
                        errorMessageEnd
                    );
                }

                // Normalize variables
                email = email.Trim().ToLower();
                website = website.Trim().ToLower();

                // Handling trailing full stop errors
                if (email.EndsWith('.') || website.EndsWith('.'))
                {
                    _logger.LogWarning(
                        "Service: Email {email} or website {website} ends with a trailing full stop.", 
                        email, website
                    );
                    throw new ArgumentException(
                        "Email or website cannot end with a trailing full stop. " +
                        errorMessageEnd
                    );
                }

                // Get domain only from email address
                var emailDomain = new MailAddress(email).Host;
                var emailDomainInfo = _domainParser.Parse(emailDomain);

                // Checking and building URI for the website address
                UriBuilder uriBuilder;
                try
                {
                    // Ensure website is a fully complete URL
                    // ftp is also supported
                    uriBuilder = new UriBuilder(
                        website.StartsWith("http", StringComparison.OrdinalIgnoreCase)
                        || website.StartsWith("ftp", StringComparison.OrdinalIgnoreCase)
                        ? website : $"https://{website}"
                    );
                }
                // Handle errors
                catch (UriFormatException exception)
                {
                    _logger.LogWarning("Service: Invalid or incomplete website {website} format.", 
                        website
                    );
                    throw new ArgumentException(
                        "Invalid or incomplete website format entered. " +
                        errorMessageEnd, exception
                    );
                }

                // Get domain only from website URL
                var websiteDomain = uriBuilder.Uri.Host;
                var websiteDomainInfo = _domainParser.Parse(websiteDomain);

                // Handle errors in domain parsing for email and website
                if (emailDomainInfo == null 
                    || string.IsNullOrWhiteSpace(emailDomainInfo.RegistrableDomain) 
                    || emailDomainInfo.RegistrableDomain == emailDomainInfo.TopLevelDomain
                    || websiteDomainInfo == null
                    || string.IsNullOrWhiteSpace(websiteDomainInfo.RegistrableDomain)
                    || websiteDomainInfo.RegistrableDomain == websiteDomainInfo.TopLevelDomain)
                {
                    _logger.LogWarning(
                        "Service: Failed to parse email {email} or website {website} domain.", 
                        email, website
                    );
                    throw new ArgumentException(
                        "Invalid or incomplete email or website format entered. " + 
                        errorMessageEnd
                    );
                }

                // Return whether the email and website domains match
                bool isMatch = emailDomainInfo.RegistrableDomain == websiteDomainInfo.RegistrableDomain;
                _logger.LogInformation(
                    "Service: Domain verification for email {email} and " + 
                    "website {website} result is {match}.", 
                    email, website, isMatch
                );
                return isMatch;
            }
            // Handle errors
            catch (ArgumentException)
            {
                throw;
            }
            catch (FormatException exception)
            {
                _logger.LogWarning(exception,
                    "Service: Invalid format for email {email} or website {website}.", 
                    email, website
                );
                throw new ArgumentException(
                    "Invalid email or website format. " +
                    errorMessageEnd, exception
                );
            }
            catch (HttpRequestException exception)
            {
                _logger.LogError(exception,
                    "Service: Network issue while verifying domain for email {email} and " + 
                    "website {website}.", 
                    email, website
                );
                throw new ApplicationException(
                    "Network issue while verifying domain. " +
                    errorMessageEnd, exception
                );
            }
            catch (Exception exception)
            {
                _logger.LogError(exception,
                    "Service: Unexpected error while verifying domain match for email {email} and " + 
                    "website {website}.", 
                    email, website
                );
                throw new ApplicationException(
                    "Domain verification failed unexpectedly. " +
                    errorMessageEnd, exception
                );
            }
        }
    }
}
