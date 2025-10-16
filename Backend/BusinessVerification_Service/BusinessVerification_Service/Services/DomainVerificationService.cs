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
        public VerificationResponseDto VerifyBusiness(DomainVerificationRequestDto verificationRequestDto)
        {
            // Initialize response DTO
            VerificationResponseDto returnResponse = new VerificationResponseDto();

            // Verify the request DTO is not null
            if (verificationRequestDto == null)
            {
                _logger.LogError(
                    "Service: Request DTO received for business verification is null."
                );

                // Return response DTO with appropriate error message
                returnResponse.Message = "Business verification failed unexpectedly. " +
                    errorMessageEnd;
                return returnResponse;
            }
            
            // Initialize Firebase DTOs
            DomainVerificationFirebaseResponseDto firebaseResponse = new DomainVerificationFirebaseResponseDto();

            // Extract variables from request DTO
            string userId = verificationRequestDto.UserId;
            string email = verificationRequestDto.BusinessEmail;
            string website = verificationRequestDto.BusinessWebsite;
            string name = verificationRequestDto.BusinessName;

            _logger.LogInformation(
                "Service: Recieved email {email}, website {website} and business name {name} " +
                "from user {user}.",
                email, website, name, userId
            );

            // Link Firebase response DTO to user
            firebaseResponse.UserId = userId;

            // Wrapper safety try catch block for the method logic
            try
            {
                // Normalize variables used for processing
                email = email.Trim().ToLower();
                website = website.Trim().ToLower();
                name = name.Trim().ToLower();

                // Handle empty input errors after trimming
                if (string.IsNullOrWhiteSpace(email)
                    || string.IsNullOrWhiteSpace(website)
                    || string.IsNullOrEmpty(name))
                {
                    _logger.LogWarning(
                        "Service: Empty email {email}, website {website} or business name {name} " + 
                        "from user {user}.", 
                        email, website, name, userId
                    );

                    // Return response DTO with appropriate error message
                    returnResponse.Message = errorMessageEnd;
                    return returnResponse;
                }

                // Checking and building URI for the website address
                try
                {
                    // Ensure website is a fully complete URL, 
                    // ftp is also supported
                    UriBuilder validateUri = new UriBuilder(
                        website.StartsWith("http", StringComparison.OrdinalIgnoreCase)
                        || website.StartsWith("ftp", StringComparison.OrdinalIgnoreCase)
                        ? website : $"https://{website}"
                    );
                }
                // Handle errors
                catch (UriFormatException exception)
                {
                    _logger.LogWarning(exception, 
                        "Service: Invalid or incomplete website {website} format for user {user}.", 
                        website, userId
                    );

                    // Return response DTO with appropriate error message
                    returnResponse.Message = "Invalid or incomplete website format entered. " + 
                        errorMessageEnd;
                    return returnResponse;
                }

                // Determine if business can be verified
                // Wrapper safety try catch block for main verification logic, 
                // catches custom error messages thrown by private methods
                try
                {
                    // Determine if the email and website domains do not match
                    if (!VerifyDomainMatch(email, website, userId))
                    {
                        // Return response DTO with appropriate message
                        returnResponse.Message = "Email and website domains entered do not match. " +  
                            errorMessageEnd;
                        return returnResponse;
                    }

                    // Determine how closely the busniness name matches the domains
                    int fuzzyMatchResult = FuzzyMatch(website, name, userId);
                    firebaseResponse.FuzzyScore = fuzzyMatchResult;

                    // For a score of >= 80 the business name can be automatically verified
                    // For a score of >= 60 and <= 79 an admin needs to verify the business name
                    // For a score of <= 59 the business name cannot be verified
                    switch (fuzzyMatchResult)
                    {
                        case >= 80:
                            // To be removed in future versions that uses email link verification
                            returnResponse.VerificationStatus = Status.Accepted;

                            returnResponse.Message = "Business successfully verified.";
                        break;
                        case >= 60:
                            firebaseResponse.RequiresAdmin = true;
                            returnResponse.VerificationStatus = Status.Pending;
                            returnResponse.Message = "Business name does not match email and " + 
                                "website domain names entered clearly enough. Admin review required.";
                        break;
                        default:
                            returnResponse.Message = "Business name does not match email and " + 
                                "website domains entered. " + errorMessageEnd;
                        break;
                    }
                }
                // Handle errors
                catch (Exception exception)
                {
                    // Return response DTO with appropriate error message
                    returnResponse.Message = exception.Message;
                    return returnResponse;
                }
            }
            // Handle errors
            catch (HttpRequestException exception)
            {
                _logger.LogError(exception,
                    "Service: Network issue during business verification for user {user}.", 
                    userId
                );

                // Return response DTO with appropriate error message
                returnResponse.Message = "Network issue while verifying business. " + 
                    errorMessageEnd;
                return returnResponse;
            }
            catch (Exception exception)
            {
                _logger.LogError(exception,
                    "Service: Unexpected error during business verification for user {user}.", 
                    userId
                );

                // Return response DTO with appropriate error message
                returnResponse.Message = "Business verification failed unexpectedly. " + 
                    errorMessageEnd;
                return returnResponse;
            }

            // To be edited for later verions of the microservice that uses email link verification
            // Using the Firebase response DTO to log verification request to Firebase
            firebaseResponse.ErrorOccurred = false;
            if (!firebaseResponse.RequiresAdmin)
            {
                firebaseResponse.OfficiallyVerified = true;
                firebaseResponse.VerifiedAt = DateTime.UtcNow;
            }

            // Add way of passing firebase DTO to Firebase

            _logger.LogInformation(
                "Service: Business verification for user {user} with email {email}, " + 
                "website {website} and business name {name} completed without errors.", 
                userId, email, website, name
            );

            // Return correct response DTO based on verification results
            return returnResponse;
        }

        // Verifies if the domain of the provided email matches the domain of the provided website
        // Returns true if they match, false and error messages otherwise
        private bool VerifyDomainMatch(string email, string website, string userId)
        {
            _logger.LogInformation(
                "Service: Domain verification for user {user} between email {email} " +
                "and website {website} started.",
                userId, email, website
            );

            // Wrapper safety try catch block for the entire method
            try
            {
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
                        "for user {user}.", 
                        email, website, userId
                    );

                    // Throw appropriate custom error message
                    throw new ArgumentException(
                        "Invalid or incomplete email or website format entered. " + 
                        errorMessageEnd
                    );
                }

                // Return whether the email and website domains match
                bool isMatch = emailDomainInfo.RegistrableDomain == websiteDomainInfo.RegistrableDomain;
                _logger.LogInformation(
                    "Service: Domain verification between email {email} and " +
                    "website {website} completed with a result of {match} for user {user}.", 
                    email, website, isMatch, userId
                );
                return isMatch;
            }
            // Handle errors throwing appropriate custom error message
            catch (ArgumentException)
            {
                throw;
            }
            catch (FormatException exception)
            {
                _logger.LogWarning(exception,
                    "Service: Invalid email format while verifying domain between email {email} and " + 
                    "website {website} for user {user}.", 
                    email, website, userId
                );
                throw new ArgumentException(
                    "Invalid or incomplete email format entered. " + 
                    errorMessageEnd, exception
                );
            }
            catch (HttpRequestException exception)
            {
                _logger.LogError(exception,
                    "Service: Network issue while verifying domain between email {email} and " + 
                    "website {website} for user {user}.", 
                    email, website, userId
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
                    "website {website} for user {user}.", 
                    email, website, userId
                );
                throw new ApplicationException(
                    "Business verification failed unexpectedly. " + 
                    errorMessageEnd, exception
                );
            }
        }

        // Fuzzy comparison between website domain and business name using FuzzySharp
        // Returns a score between 0 and 100
        private int FuzzyMatch(string website, string name, string userId)
        {
            _logger.LogInformation(
                "Service: Fuzzy comparison for user {user} between website {website} " +
                "and business name {name} started.",
                userId, website, name
            );

            // Wrapper safety try catch block for the entire method
            try
            {
                // Get domain only from website
                var websiteDomainTld = new UriBuilder(website).Uri.Host;
                var websiteDomainInfo = _domainParser.Parse(websiteDomainTld);
                string websiteDomainOnly = websiteDomainInfo.Domain;

                // Do a fuzzy comparison using FuzzySharp
                // Various algorithms can be used,
                // PartialTokenSetRatio is a good balance for this use case
                int score = Fuzz.PartialTokenSetRatio(websiteDomainOnly, name);

                _logger.LogInformation(
                    "Service: Fuzzy comparison for user {user} between website {website} " + 
                    "and business name {name} completed with a score of {score}.\n" + 
                    "Thresholds:\n" + 
                    ">= 80 - automatically verified\n" + 
                    ">= 60 and <= 79 - admin must verify\n" + 
                    "<= 59 - cannot verify", 
                    userId, website, name, score
                );

                // Return fuzzy comparison result
                return score;
            }
            // Handle errors throwing appropriate custom error message
            catch (HttpRequestException exception)
            {
                _logger.LogError(exception,
                    "Service: Network issue during fuzzy comparison for user {user}.", 
                    userId
                );
                throw new ApplicationException(
                    "Network issue while verifying business. " + 
                    errorMessageEnd, exception
                );
            }
            catch (Exception exception)
            {
                _logger.LogError(exception,
                    "Service: Unexpected error during fuzzy comparison for user {user}.", 
                    userId
                );
                throw new ApplicationException(
                    "Business verification failed unexpectedly. " + 
                    errorMessageEnd, exception
                );
            }
        }
    }
}
