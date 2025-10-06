using Nager.PublicSuffix;
using System;
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
                    throw new ArgumentNullException(nameof(email), "No email recieved.");
                }
                if (string.IsNullOrWhiteSpace(website))
                {
                    _logger.LogWarning(
                        "VerifyDomainMatch was called with empty website."
                    );
                    throw new ArgumentNullException(nameof(website), "No website recieved.");
                }

                // Normalize variables
                email = email.Trim().ToLower();
                website = website.Trim().ToLower();

                // Get domain only from email address
                var emailDomain = new MailAddress(email).Host;
                var emailDomainInfo = _domainParser.Parse(emailDomain);

                // Ensure website is a fully complete URL
                var uriBuilder = new UriBuilder(
                    website.StartsWith("http", StringComparison.OrdinalIgnoreCase) 
                    ? website : $"https://{website}"
                );

                // Get domain only from website URL
                var websiteDomain = uriBuilder.Uri.Host;
                var websiteDomainInfo = _domainParser.Parse(websiteDomain);

                // Handle errors in domain parsing
                if (emailDomainInfo == null)
                {
                    _logger.LogWarning("Failed to parse email domain: {email}", email);
                    throw new ArgumentException("Invalid email format entered.");
                }
                if (websiteDomainInfo == null)
                {
                    _logger.LogWarning("Failed to parse website domain: {website}", website);
                    throw new ArgumentException("Invalid website format entered.");
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
                throw new ArgumentException("Invalid email or website format.", exception);
            }
            catch (HttpRequestException exception)
            {
                _logger.LogError(exception, 
                    "Network issue while verifying domain for email {email} and website {website}.", 
                    email, website
                );
                throw new ApplicationException("Network issue while verifying domain.", exception);
            }
            catch (Exception exception)
            {
                _logger.LogError(exception, 
                    "Unexpected error while verifying domain for email {email} and website {website}.", 
                    email, website
                );
                throw new ApplicationException("Domain verification failed unexpectedly.", exception);
            }
        }
    }
}
