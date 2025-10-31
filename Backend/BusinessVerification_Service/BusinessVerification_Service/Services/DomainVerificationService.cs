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
        private readonly IFirestoreFunctionsService _firestoreFunctionsService;

        // Constructor for dependency injection
        public DomainVerificationService(ILogger<DomainVerificationService> logger, 
            IDomainParser domainParser, IFirestoreFunctionsService firestoreFunctionsService)
        {
            _logger = logger;
            _domainParser = domainParser;
            _firestoreFunctionsService = firestoreFunctionsService;
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

                // Firebase DTO will not be written to Firebase here, 
                // as there is no user to link to

                // Return response DTO with appropriate error message
                returnResponse.Message = "Business verification failed unexpectedly. " +
                    errorMessageEnd;
                return returnResponse;
            }
            
            // Initialize Firebase DTOs
            DomainVerificationFirebaseResponseDto firebaseResponse = new DomainVerificationFirebaseResponseDto();

            // Extract variables from request DTO, 
            // just for easier use
            string userId = verificationRequestDto.UserId;
            string email = verificationRequestDto.BusinessEmail;
            string website = verificationRequestDto.BusinessWebsite;
            string name = verificationRequestDto.BusinessName;

            _logger.LogInformation(
                "Service: Recieved user {user} email {email}, website {website} " +
                "and business name {name}.",
                userId, email, website, name
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

                    // Write Firebase DTO to Firebase
                    _firestoreFunctionsService.WriteVerificationRequest(firebaseResponse);

                    // Return response DTO with appropriate error message
                    returnResponse.Message = errorMessageEnd;
                    return returnResponse;
                }

                // Checking for supported schemes in website address
                if (website.Contains("://"))
                {
                    // Get first part of website address before ://
                    string scheme = website.Split("://")[0].ToLower();

                    // Count number of schemes in website address
                    int schemeCount = website.Split("://").Length - 1;

                    // There should not be more that 1 scheme
                    // Only http, https and ftp are supported
                    if (schemeCount > 1 
                        || (scheme != "http" && scheme != "https" && scheme != "ftp"))
                    {
                        _logger.LogWarning(
                            "Service: Invalid, unsupported or more than one scheme in " + 
                            "user {user} website {website}.", 
                            userId, website
                        );

                        // Write Firebase DTO to Firebase
                        _firestoreFunctionsService.WriteVerificationRequest(firebaseResponse);

                        // Return response DTO with appropriate error message
                        returnResponse.Message = "Invalid or incomplete website format entered. " + 
                            errorMessageEnd;
                        return returnResponse;
                    }
                }

                // Checking and building URI for the website address
                try
                {
                    // Ensure website is a fully complete URL for later domain parsing
                    UriBuilder validateUri = new UriBuilder(
                        website.StartsWith("http", StringComparison.OrdinalIgnoreCase)
                        || website.StartsWith("ftp", StringComparison.OrdinalIgnoreCase)
                        ? website 
                        : $"https://{website}"
                    );
                }
                // Handle errors throwing appropriate custom error message
                catch (UriFormatException exception)
                {
                    _logger.LogWarning(exception,
                        "Service: Invalid or incomplete user {user} website {website} format.", 
                        userId, website
                    );

                    // Write Firebase DTO to Firebase
                    _firestoreFunctionsService.WriteVerificationRequest(firebaseResponse);

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
                        // Write Firebase DTO to Firebase
                        _firestoreFunctionsService.WriteVerificationRequest(firebaseResponse);

                        // Return response DTO with appropriate message
                        returnResponse.VerificationStatus = Status.Rejected;
                        returnResponse.Message = "Email and website domains entered do not match. " +  
                            errorMessageEnd;
                        return returnResponse;
                    }

                    // Determine how closely the busniness name matches the domains
                    int fuzzyMatchResult = FuzzyMatch(website, name, userId);
                    firebaseResponse.FuzzyScore = fuzzyMatchResult;

                    // Switch case used for thresholds
                    switch (fuzzyMatchResult)
                    {
                        // For a score of >= 90 the business name can be automatically verified
                        case >= 90:
                            // To be edited in future versions that uses email link verification
                            firebaseResponse.VerificationStatus = Status.Accepted;
                            returnResponse.VerificationStatus = Status.Accepted;
                            returnResponse.Message = "Business successfully verified.";
                        break;

                        // For a score of >= 65 and <= 89 an admin needs to verify the business name
                        case >= 65:
                            firebaseResponse.VerificationStatus = Status.Pending;
                            returnResponse.VerificationStatus = Status.Pending;
                            returnResponse.Message = "Business name does not match email and " + 
                                "website domain names entered clearly enough. Admin review required.";
                        break;

                        // For a score of <= 64 the business name cannot be verified
                        default:
                            returnResponse.VerificationStatus = Status.Rejected;
                            returnResponse.Message = "Business name does not match email and " + 
                                "website domains entered. " + errorMessageEnd;
                        break;
                    }
                }
                // Handle errors throwing appropriate custom error message
                catch (Exception exception)
                {
                    // Write Firebase DTO to Firebase
                    _firestoreFunctionsService.WriteVerificationRequest(firebaseResponse);

                    // Return response DTO with appropriate error message
                    returnResponse.Message = exception.Message;
                    return returnResponse;
                }
            }
            // Handle errors throwing appropriate custom error message
            catch (Exception exception)
            {
                _logger.LogError(exception,
                    "Service: Unexpected error during business verification for user {user}.", 
                    userId
                );

                // Write Firebase DTO to Firebase
                _firestoreFunctionsService.WriteVerificationRequest(firebaseResponse);

                // Return response DTO with appropriate error message
                returnResponse.Message = "Business verification failed unexpectedly. " + 
                    errorMessageEnd;
                return returnResponse;
            }

            // To be edited in future versions that uses email link verification
            // Using the Firebase response DTO to push verification request to Firebase
            firebaseResponse.ErrorOccurred = false;
            if (firebaseResponse.VerificationStatus == Status.Accepted)
            {
                firebaseResponse.VerifiedAt = DateTime.UtcNow;
            }

            // Write Firebase DTO to Firebase
            _firestoreFunctionsService.WriteVerificationRequest(firebaseResponse);

            _logger.LogInformation(
                "Service: Business verification for user {user} with email {email}, " + 
                "website {website} and business name {name} completed without errors.\n" + 
                "Verification properties passed to Firebase service.", 
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
                var emailHost = new MailAddress(email).Host;
                var emailDomainInfo = _domainParser.Parse(emailHost);

                // Get domain only from website URL
                var websiteHost = new UriBuilder(website).Uri.Host;
                var websiteDomainInfo = _domainParser.Parse(websiteHost);

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
                        "Service: Failed to parse user {user} email {email} or website {website} domain.", 
                        userId, email, website
                    );

                    throw new ArgumentException(
                        "Invalid or incomplete email or website format entered. " + 
                        errorMessageEnd
                    );
                }

                // Determine whether the email and website domains match
                bool isMatch = emailDomainInfo.RegistrableDomain == websiteDomainInfo.RegistrableDomain;

                _logger.LogInformation(
                    "Service: Domain verification for user {user} between email {email} and " +
                    "website {website} completed with a result of {match}.",
                    userId, email, website, isMatch
                );

                // Return whether the email and website domains match
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
                    "Service: Invalid email format while verifying for user {user} domain between " + 
                    "email {email} and website {website}.", 
                    userId, email, website
                );

                throw new ArgumentException(
                    "Invalid or incomplete email format entered. " + 
                    errorMessageEnd, exception
                );
            }
            catch (Exception exception)
            {
                _logger.LogError(exception,
                    "Service: Unexpected error during domain verification for user {user}.", 
                    userId
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
                // WeightedRatio is a good balance for this use case
                int score = Fuzz.WeightedRatio(websiteDomainOnly, name);

                _logger.LogInformation(
                    "Service: Fuzzy comparison for user {user} between website {website} " + 
                    "and business name {name} completed with a score of {score}.\n" + 
                    "Thresholds:\n" + 
                    ">= 90 - automatically verified\n" + 
                    ">= 65 and <= 89 - admin must verify\n" + 
                    "<= 64 - cannot verify", 
                    userId, website, name, score
                );

                // Return fuzzy comparison result
                return score;
            }
            // Handle errors throwing appropriate custom error message
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
