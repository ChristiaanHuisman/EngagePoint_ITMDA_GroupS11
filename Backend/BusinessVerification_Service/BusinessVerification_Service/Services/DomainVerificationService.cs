using BusinessVerification_Service.Dtos;
using BusinessVerification_Service.Interfaces;
using FuzzySharp;
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

        // Standard error message ending for displaying user error messages
        const string errorMessageEnd = "Please ensure all details are entered correctly " + 
            "and try again, contact support if the issue persists.";

        // Main verification method called by the controller
        // Implements all private methods and returns DTO of results
        public VerificationResponseDto VerifyBusiness(string email, string website, string name)
        {
            // Wrapper safety try block for the entire method
            try
            {
                _logger.LogInformation(
                    "Service: Recieved email {email}, website {website} and business name {name}.", 
                    email, website, name
                );

                // Normalize variables
                email = email.Trim().ToLower();
                website = website.Trim().ToLower();
                name = name.Trim().ToLower();

                // Handle empty input errors after trimming
                if (string.IsNullOrWhiteSpace(email)
                    || string.IsNullOrWhiteSpace(website)
                    || string.IsNullOrEmpty(name))
                {
                    _logger.LogWarning(
                        "Service: Empty email {email}, website {website} or business name {name}.", 
                        email, website, name
                    );
                    throw new ArgumentException(errorMessageEnd);
                }

                // Checking and building URI for the website address
                try
                {
                    // Ensure website is a fully complete URL, 
                    // ftp is also supported
                    UriBuilder uriBuilder = new UriBuilder(
                        website.StartsWith("http", StringComparison.OrdinalIgnoreCase)
                        || website.StartsWith("ftp", StringComparison.OrdinalIgnoreCase)
                        ? website : $"https://{website}"
                    );
                }
                // Handle errors
                catch (UriFormatException exception)
                {
                    _logger.LogWarning("Service: Invalid or incomplete website {website} format " + 
                        "for email {email} and business name {name}.", 
                        website, email, name
                    );
                    throw new ArgumentException(
                        "Invalid or incomplete website format entered. " + 
                        errorMessageEnd, exception
                    );
                }

                // Final result of business being verified
                bool completelyVerified = false;

                // Determine if business can be verified
                if (VerifyDomainMatch(email, website, name))
                {
                    // Determine if busniness name matches domains
                    int fuzzyMatchResult = FuzzyMatch(email, website, name);

                    // Currently in .NET 8 if statements are needed for checking thresholds
                    // Would prefer to use switch case for checking thresholds, 
                    // but need to move to .NET 9 then
                    // For a score of >= 80 the business name can be automatically verified
                    if (fuzzyMatchResult >= 80)
                    {
                        completelyVerified = true;
                    }
                    // For a score of >= 60 and <= 79 an admin needs to verify the business name
                    else if (fuzzyMatchResult >= 60)
                    {
                        // Admin verification logic
                    }
                    // For a score of <= 59 the business name cannot be verified
                }

                // Continue with returning result
            }
            // Handle errors
            catch (ArgumentException)
            {
                throw;
            }
            catch (HttpRequestException exception)
            {
                _logger.LogError(exception,
                    "Service: Network issue during business verification for email {email}, " + 
                    "website {website} and business name {name}.", 
                    email, website, name
                );
                throw new ApplicationException(
                    "Network issue while verifying business. " + 
                    errorMessageEnd, exception
                );
            }
            catch (Exception exception)
            {
                _logger.LogError(exception,
                    "Service: Unexpected error during business verification for email {email}, " + 
                    "website {website} and business name {name}.", 
                    email, website, name
                );
                throw new ApplicationException(
                    "Business verification failed unexpectedly. " + 
                    errorMessageEnd, exception
                );
            }
        }

        // Verifies if the domain of the provided email matches the domain of the provided website
        // Returns true if they match, false and error messages otherwise
        private bool VerifyDomainMatch(string email, string website, string name)
        {
            // Wrapper safety try block for the entire method
            try
            {
                _logger.LogInformation(
                    "Service: Domain verification for email {email}, " +
                    "website {website} and business name {name} started.", 
                    email, website, name
                );

                // Get domain only from email address
                var emailDomain = new MailAddress(email).Host;
                var emailDomainInfo = _domainParser.Parse(emailDomain);

                // Get domain only from website URL
                var websiteDomainTld = new UriBuilder(website).Uri.Host;
                var websiteDomainInfo = _domainParser.Parse(websiteDomainTld);

                // Handle errors in domain parsing for email and website that follow rules, 
                // but can still be incorrect
                if (emailDomainInfo == null 
                    || string.IsNullOrWhiteSpace(emailDomainInfo.RegistrableDomain) 
                    || emailDomainInfo.RegistrableDomain == emailDomainInfo.TopLevelDomain
                    || websiteDomainInfo == null
                    || string.IsNullOrWhiteSpace(websiteDomainInfo.RegistrableDomain)
                    || websiteDomainInfo.RegistrableDomain == websiteDomainInfo.TopLevelDomain)
                {
                    _logger.LogWarning(
                        "Service: Failed to parse email {email} or website {website} domain " + 
                        "for business name {name}.", 
                        email, website, name
                    );
                    throw new ArgumentException(
                        "Invalid or incomplete email or website format entered. " + 
                        errorMessageEnd
                    );
                }

                // Return whether the email and website domains match
                bool isMatch = emailDomainInfo.RegistrableDomain == websiteDomainInfo.RegistrableDomain;
                _logger.LogInformation(
                    "Service: Domain verification between email {email} and " +
                    "website {website} completed with a result of {match} for business name {name}.", 
                    email, website, isMatch, name
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
                    "Service: Invalid format while verifying domain between email {email} and " + 
                    "website {website} for business name {name}.", 
                    email, website, name
                );
                throw new ArgumentException(
                    "Invalid email or website format. " + 
                    errorMessageEnd, exception
                );
            }
            catch (HttpRequestException exception)
            {
                _logger.LogError(exception,
                    "Service: Network issue while verifying domain between email {email} and " + 
                    "website {website} for business name {name}.", 
                    email, website, name
                );
                throw new ApplicationException(
                    "Network issue while verifying business. " + 
                    errorMessageEnd, exception
                );
            }
            catch (Exception exception)
            {
                _logger.LogError(exception,
                    "Service: Unexpected error while verifying domain match between email {email} and " + 
                    "website {website} for business name {name}.", 
                    email, website, name
                );
                throw new ApplicationException(
                    "Business verification failed unexpectedly. " + 
                    errorMessageEnd, exception
                );
            }
        }

        // Fuzzy comparison between website domain and business name using FuzzySharp
        // Returns a score between 0 and 100
        private int FuzzyMatch(string email, string website, string name)
        {
            // Wrapper safety try block for the entire method
            try
            {
                _logger.LogInformation(
                    "Service: Fuzzy comparison for email {email} between website {website} " + 
                    "and business name {name} started.", 
                    email, website, name
                );

                // Get domain only from website
                var websiteDomainTld = new UriBuilder(website).Uri.Host;
                var websiteDomainInfo = _domainParser.Parse(websiteDomainTld);
                string websiteDomainOnly = websiteDomainInfo.Domain;

                // Do a fuzzy comparison using FuzzySharp
                // Various algorithms can be used,
                // PartialTokenSetRatio is a good balance for this use case
                int score = Fuzz.PartialTokenSetRatio(websiteDomainOnly, name);

                _logger.LogInformation(
                    "Service: Fuzzy comparison for email {email} between website {website} " + 
                    "and business name {name} completed with a score of {score}.\n" + 
                    "Thresholds:\n" + 
                    ">= 80 - auto verified\n" + 
                    ">= 60 and <= 79 - admin must verify\n" + 
                    "<= 59 - can't verify", 
                    email, website, name, score
                );

                // Return fuzzy comparison result
                return score;
            }
            // Handle errors
            catch (HttpRequestException exception)
            {
                _logger.LogError(exception,
                    "Service: Network issue during fuzzy comparison for email {email} between " + 
                    "website {website} and business name {name}.", 
                    email, website, name
                );
                throw new ApplicationException(
                    "Network issue while verifying business. " + 
                    errorMessageEnd, exception
                );
            }
            catch (Exception exception)
            {
                _logger.LogError(exception,
                    "Service: Unexpected error during fuzzy comparison for email {email} between " +
                    "website {website} and business name {name}.", 
                    email, website, name
                );
                throw new ApplicationException(
                    "Business verification failed unexpectedly. " + 
                    errorMessageEnd, exception
                );
            }
        }
    }
}
