using Nager.PublicSuffix;
using System.Net.Mail;

namespace BusinessVerification_Service.Services
{
    public class DomainVerificationService
    {
        private readonly ILogger<DomainVerificationService> _logger;
        private readonly IDomainParser _domainParser;

        public DomainVerificationService(ILogger<DomainVerificationService> logger, IDomainParser domainParser)
        {
            _logger = logger;
            _domainParser = domainParser;
        }

        // Verifies if the domain of the provided email matches the domain of the provided website
        // Returns true if they match, false and error messages otherwise
        public bool VerifyDomainMatch(string email, string website)
        {
            try
            {
                _logger.LogInformation(
                    "Domain verification for email {email} and website {website} started.",
                    email, website
                );

                // Handle empty errors
                if (string.IsNullOrWhiteSpace(email))
                {
                    _logger.LogWarning(
                        "VerifyDomainMatch was called with empty email."
                    );
                    throw new ArgumentNullException(nameof(email), 
                        "No email recieved. " +
                        "Please ensure all details are entered correctly and try again, " +
                        "or contact support if the issue persists."
                    );
                }
                if (string.IsNullOrWhiteSpace(website))
                {
                    _logger.LogWarning(
                        "VerifyDomainMatch was called with empty website."
                    );
                    throw new ArgumentNullException(nameof(website),
                        "No website recieved. " +
                        "Please ensure all details are entered correctly and try again, " +
                        "or contact support if the issue persists."
                    );
                }

                // Normalize variables
                email = email.Trim().ToLower();
                website = website.Trim().ToLower();

                // Handling trailing full stop errors
                if (email.EndsWith('.'))
                {
                    _logger.LogWarning("Email {email} ends with a trailing full stop.", 
                        email
                    );
                    throw new ArgumentException("Email cannot end with a trailing full stop. " +
                        "Please ensure all details are entered correctly and try again, " +
                        "or contact support if the issue persists."
                    );
                }
                if (website.EndsWith('.'))
                {
                    _logger.LogWarning("Website {website} ends with a trailing full stop.",
                        website
                    );
                    throw new ArgumentException("Website cannot end with a trailing full stop. " +
                        "Please ensure all details are entered correctly and try again, " +
                        "or contact support if the issue persists."
                    );
                }

                // Get domain only from email address
                var emailDomain = new MailAddress(email).Host;
                var emailDomainInfo = _domainParser.Parse(emailDomain);

                // Ensure website is a fully complete URL
                // ftp is also supported
                var uriBuilder = new UriBuilder(
                    website.StartsWith("http", StringComparison.OrdinalIgnoreCase) 
                    || website.StartsWith("ftp", StringComparison.OrdinalIgnoreCase) 
                    ? website : $"https://{website}"
                );

                // Get domain only from website URL
                var websiteDomain = uriBuilder.Uri.Host;
                var websiteDomainInfo = _domainParser.Parse(websiteDomain);

                // Handle errors in domain parsing
                if (emailDomainInfo == null 
                    || string.IsNullOrWhiteSpace(emailDomainInfo.RegistrableDomain) 
                    || emailDomainInfo.RegistrableDomain == emailDomainInfo.TopLevelDomain)
                {
                    _logger.LogWarning("Failed to parse email {email} domain.", email);
                    throw new ArgumentException(
                        "Invalid or incomplete email format entered. " +
                        "Please ensure all details are entered correctly and try again, " +
                        "or contact support if the issue persists."
                    );
                }
                if (websiteDomainInfo == null 
                    || string.IsNullOrWhiteSpace(websiteDomainInfo.RegistrableDomain) 
                    || websiteDomainInfo.RegistrableDomain == websiteDomainInfo.TopLevelDomain)
                {
                    _logger.LogWarning("Failed to parse website {website} domain.", website);
                    throw new ArgumentException(
                        "Invalid or incomplete website format entered. " +
                        "Please ensure all details are entered correctly and try again, " +
                        "or contact support if the issue persists."
                    );
                }

                // Return if the email and website domains match
                bool isMatch = emailDomainInfo.RegistrableDomain == websiteDomainInfo.RegistrableDomain;
                _logger.LogInformation(
                    "Domain verification for email {email} and website {website} result is {isMatch}.", 
                    email, website, isMatch
                );
                return isMatch;
            }
            // Handle errors
            catch (ArgumentNullException)
            {
                throw;
            }
            catch (FormatException exception)
            {
                _logger.LogWarning(exception, 
                    "Invalid format for email {email} and/or website {website}.", 
                    email, website
                );
                throw new ArgumentException(
                    "Invalid email or website format. " +
                    "Please ensure all details are entered correctly and try again, " +
                    "or contact support if the issue persists.", 
                    exception
                );
            }
            catch (HttpRequestException exception)
            {
                _logger.LogError(exception, 
                    "Network issue while verifying domain for email {email} and website {website}.", 
                    email, website
                );
                throw new ApplicationException(
                    "Network issue while verifying domain. " +
                    "Please ensure all details are entered correctly and try again, " +
                    "or contact support if the issue persists.", 
                    exception
                );
            }
            catch (Exception exception)
            {
                _logger.LogError(exception, 
                    "Unexpected error while verifying domain match for email {email} and website {website}.", 
                    email, website
                );
                throw new ApplicationException(
                    "Domain verification failed unexpectedly. " +
                    "Please ensure all details are entered correctly and try again, " +
                    "or contact support if the issue persists.", 
                    exception
                );
            }
        }
    }
}
