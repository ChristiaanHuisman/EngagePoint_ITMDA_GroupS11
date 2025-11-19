using BusinessVerification_Service.Api.Dtos;
using BusinessVerification_Service.Api.Interfaces.HelpersInterfaces;
using BusinessVerification_Service.Api.Interfaces.ServicesInterfaces;
using BusinessVerification_Service.Api.Models;
using FirebaseAdmin.Auth;
using Nager.PublicSuffix;
using System.Net.Mail;

namespace BusinessVerification_Service.Api.Services
{
    public class BusinessVerificationService : IBusinessVerificationService
    {
        // Inject dependencies
        private readonly IDomainParser _domainParser;
        private readonly IFirebaseHelper _firebaseHelper;
        private readonly IDomainNameHelper _domainNameHelper;
        private readonly IWebsiteAddressHelper _websiteAddressHelper;
        private readonly IFirestoreService _firestoreService;
        private readonly INormalizationAndValidationHelper
            _normalizationAndValidationHelper;
        private readonly IEmailVerificationService _emailVerificationService;

        // Constructor for dependency injection
        public BusinessVerificationService(IDomainParser domainParser,
            IFirebaseHelper firebaseHelper, IDomainNameHelper domainNameHelper,
            IWebsiteAddressHelper websiteAddressHelper, IFirestoreService firestoreService,
            INormalizationAndValidationHelper normalizationAndValidationHelper,
            IEmailVerificationService emailVerificationService)
        {
            _domainParser = domainParser;
            _firebaseHelper = firebaseHelper;
            _domainNameHelper = domainNameHelper;
            _websiteAddressHelper = websiteAddressHelper;
            _firestoreService = firestoreService;
            _normalizationAndValidationHelper = normalizationAndValidationHelper;
            _emailVerificationService = emailVerificationService;
        }

        // Standard respnose messages
        const string errorMessageEnd = "Please ensure all account details are correct " +
            "and try again in a few minutes, contact support if the issue persists.";

        // Collection names in Firestore
        const string userCollection = "users";
        const string verificationCollection = "businessVerification";

        // Return an tuple of parsed domain DTOs of email and website
        public (ParsedDomainDto? ParsedEmailDomain, ParsedDomainDto? ParsedWebsiteDomain)
            GetDomainInfo(string emailAddress, string websiteAddress)
        {
            try
            {
                // Get the domains from email and website
                string emailHost = new MailAddress(emailAddress).Host;
                string websiteHost = new Uri(websiteAddress).Host;

                // Get the parsed domain info for email and website
                DomainInfo emailDomainInfo = _domainParser.Parse(emailHost);
                DomainInfo websiteDomainInfo = _domainParser.Parse(websiteHost);

                // Check for nulls and build the DTOs for email and website
                return (
                    emailDomainInfo != null ? new ParsedDomainDto
                    {
                        registrableDomain = emailDomainInfo.RegistrableDomain,
                        topLevelDomain = emailDomainInfo.TopLevelDomain,
                        domain = emailDomainInfo.Domain
                    } : null,
                    websiteDomainInfo != null ? new ParsedDomainDto
                    {
                        registrableDomain = websiteDomainInfo.RegistrableDomain,
                        topLevelDomain = websiteDomainInfo.TopLevelDomain,
                        domain = websiteDomainInfo.Domain
                    } : null
                );
            }
            catch
            {
                // If an error occurs with parsing or input has invalid formatting
                return (null, null);
            }
        }

        // Return a response DTO to send back to the user Flutter app
        public async Task<BusinessVerificationResponseDto> BusinessVerificationProcess(
            string? authorizationHeader)
        {
            // Create response DTO instance
            BusinessVerificationResponseDto responseDto = new();

            try
            {
                // Remove tag or set as null
                string? authorizationToken = authorizationHeader?.Trim().Replace("Bearer ", "");
                if (string.IsNullOrWhiteSpace(authorizationToken))
                {
                    // Returning a response
                    responseDto.message = $"Missing or invalid authorization token. " +
                        $"{errorMessageEnd}";
                    return responseDto;
                }

                // Check token validity and get the decoded token
                FirebaseToken? decodedToken = await _firebaseHelper.GetDecodedAuthorizationToken(
                    authorizationToken);
                if (decodedToken == null)
                {
                    // Returning a response
                    responseDto.message = $"Could not verify authorization token. " +
                        $"{errorMessageEnd}";
                    return responseDto;
                }

                // Get the relevant user ID
                string? userId = _firebaseHelper.GetUserIdFromToken(decodedToken);
                if (userId == null)
                {
                    // Returning a response
                    responseDto.message = $"Could not verify user ID in database. " +
                        $"{errorMessageEnd}";
                    return responseDto;
                }

                // Get relevant Firebase document paths
                string firestoreUserDocumentPath = $"{userCollection}/{userId}";
                string firestoreBusinessVerificationDocumentPath = $"{userCollection}/" +
                    $"{userId}/{verificationCollection}/{userId}";
                
                // Retrieve documents from Firestore and convert to relevant models
                UserModel? userModel = await _firestoreService.GetDocumentFromFirestore<UserModel>(
                    firestoreUserDocumentPath);
                if (userModel == null)
                {
                    // Returning a response
                    responseDto.message = $"Could not find user in database. " +
                        $"{errorMessageEnd}";
                    return responseDto;
                }
                else if (userModel.role != userRole.business)
                {
                    // Returning a response
                    responseDto.message = $"Only business accounts can request business " +
                        $"verification. {errorMessageEnd}";
                    return responseDto;
                }
                userModel.verificationRequestedAt = DateTime.UtcNow;

                // Set up relavent business verification model
                BusinessVerificationModel? businessVerificationModel = await
                    _firestoreService.GetDocumentFromFirestore<BusinessVerificationModel>(
                    firestoreBusinessVerificationDocumentPath);
                businessVerificationModel ??= new();
                businessVerificationModel.SetVerificationRequestedAt(userModel);
                businessVerificationModel.SetEmailVerified(userModel);
                businessVerificationModel.errorOccured = false;
                businessVerificationModel.fuzzyScore = null;
                businessVerificationModel.attemptNumber++;

                // Normalize data
                userModel.email = _normalizationAndValidationHelper.NormalizeString(
                    userModel.email);
                userModel.email = _normalizationAndValidationHelper.RemoveAllWhitespace(
                    userModel.email);
                userModel.website = _normalizationAndValidationHelper.NormalizeString(
                    userModel.website);
                userModel.website = _normalizationAndValidationHelper.RemoveAllWhitespace(
                    userModel.website);
                string? businessName = _normalizationAndValidationHelper.NormalizeString(
                    userModel.name);

                // Validate data exists
                if (!_normalizationAndValidationHelper.IsPopulated(
                    userModel.email, userModel.website, businessName))
                {
                    // Execute writing to Firestore documents and returning a response
                    businessVerificationModel.errorOccured = true;
                    responseDto.message = $"Some user data is missing. {errorMessageEnd}";
                    await _firestoreService.SetDocumentByFirestorePath(
                        firestoreUserDocumentPath, userModel);
                    await _firestoreService.SetDocumentByFirestorePath(
                        firestoreBusinessVerificationDocumentPath, businessVerificationModel);
                    return responseDto;
                }

                // Validate email and website format
                if (!_normalizationAndValidationHelper.IsValidEmailAddress(userModel.email))
                {
                    // Execute writing to Firestore documents and returning a response
                    businessVerificationModel.errorOccured = true;
                    responseDto.message = $"Invalid email address received. {errorMessageEnd}";
                    await _firestoreService.SetDocumentByFirestorePath(
                        firestoreUserDocumentPath, userModel);
                    await _firestoreService.SetDocumentByFirestorePath(
                        firestoreBusinessVerificationDocumentPath, businessVerificationModel);
                    return responseDto;
                }
                if (!_websiteAddressHelper.VerifyWebsiteAddressScheme(userModel.website))
                {
                    // Execute writing to Firestore documents and returning a response
                    businessVerificationModel.errorOccured = true;
                    responseDto.message = $"Invalid website address scheme received. " +
                        $"{errorMessageEnd}";
                    await _firestoreService.SetDocumentByFirestorePath(
                        firestoreUserDocumentPath, userModel);
                    await _firestoreService.SetDocumentByFirestorePath(
                        firestoreBusinessVerificationDocumentPath, businessVerificationModel);
                    return responseDto;
                }
                userModel.website = _websiteAddressHelper.BuildUriWebsiteAddress(
                    userModel.website);

                // Get tuple of parsed domain DTOs for email and website addresses
                (ParsedDomainDto? parsedEmailDomain, ParsedDomainDto? parsedWebsiteDomain) =
                    GetDomainInfo(userModel.email, userModel.website);

                // Handle errors in domain parsing for email and website or invalid formats
                if (parsedEmailDomain == null || parsedWebsiteDomain == null)
                {
                    // Execute writing to Firestore documents and returning a response
                    businessVerificationModel.errorOccured = true;
                    responseDto.message = $"Email or website address could not be processed " +
                        $"properly and might have an invalid format. {errorMessageEnd}";
                    await _firestoreService.SetDocumentByFirestorePath(
                        firestoreUserDocumentPath, userModel);
                    await _firestoreService.SetDocumentByFirestorePath(
                        firestoreBusinessVerificationDocumentPath, businessVerificationModel);
                    return responseDto;
                }

                // Check if the top level domain is in the public suffix list
                if (string.IsNullOrWhiteSpace(parsedEmailDomain?.topLevelDomain)
                    || string.IsNullOrWhiteSpace(parsedWebsiteDomain?.topLevelDomain))
                {
                    // Execute writing to Firestore documents and returning a response
                    responseDto.message = $"Top level domain not recognized. {errorMessageEnd}";
                    await _firestoreService.SetDocumentByFirestorePath(firestoreUserDocumentPath, userModel);
                    await _firestoreService.SetDocumentByFirestorePath(
                        firestoreBusinessVerificationDocumentPath, businessVerificationModel);
                    return responseDto;
                }

                // Use parsed domain information to check if email and website domains match
                if (parsedEmailDomain.registrableDomain != parsedWebsiteDomain.registrableDomain)
                {
                    // Execute writing to Firestore documents and returning a response
                    userModel.verificationStatus = userVerificationStatus.rejected;
                    businessVerificationModel.SetVerificationStatus(userModel);
                    responseDto.message = $"Email and website domains do not match. " +
                        $"{errorMessageEnd}";
                    await _firestoreService.SetDocumentByFirestorePath(
                        firestoreUserDocumentPath, userModel);
                    await _firestoreService.SetDocumentByFirestorePath(
                        firestoreBusinessVerificationDocumentPath, businessVerificationModel);
                    return responseDto;
                }

                // Classify model verification status based on fuzzy score
                int fuzzyScore = _domainNameHelper.FuzzyMatchScore(parsedEmailDomain.domain,
                    businessName);
                businessVerificationModel.fuzzyScore = fuzzyScore;

                // Email verification needs to take place before admin verification if needed
                switch (fuzzyScore)
                {
                    // For a score of >= 90 the business name can be automatically verified
                    case >= 90:
                        if (userModel.emailVerified == true)
                        {
                            userModel.verificationStatus = userVerificationStatus.accepted;
                            businessVerificationModel.SetVerificationStatus(userModel);
                        }
                        else
                        {
                            await _emailVerificationService.NewVerificationEmail(userModel, userId);
                            userModel.verificationStatus = userVerificationStatus.pendingEmail;
                            businessVerificationModel.SetVerificationStatus(userModel);
                        }
                    break;

                    // For a score of >= 60 and <= 89 an admin needs to verify the business name
                    case >= 60:
                        if (userModel.emailVerified == true)
                        {
                            userModel.verificationStatus = userVerificationStatus.pendingAdmin;
                            businessVerificationModel.SetVerificationStatus(userModel);
                        }
                        else
                        {
                            await _emailVerificationService.NewVerificationEmail(userModel, userId);
                            userModel.verificationStatus = userVerificationStatus.pendingEmail;
                            businessVerificationModel.SetVerificationStatus(userModel);
                        }
                    break;

                    // For a score of <= 59 the business name cannot be verified
                    default:
                        userModel.verificationStatus = userVerificationStatus.rejected;
                        businessVerificationModel.SetVerificationStatus(userModel);
                    break;
                }

                // Assign appropriate message to the response DTO based on
                // the current model verification status
                switch (userModel.verificationStatus)
                {
                    case userVerificationStatus.accepted:
                        responseDto.message = $"Your business verification request has been " +
                            $"approved. The next time you log in, you should be verified.";
                    break;

                    case userVerificationStatus.pendingEmail:
                        responseDto.message = $"Your business verification request is pending " +
                            $"email confirmation. Please check your inbox periodically for " +
                            $"instructions.";
                    break;

                    case userVerificationStatus.pendingAdmin:
                        responseDto.message = $"Your verification request is pending review " +
                            $"by an admin. You will be notified once it's processed.";
                    break;

                    case userVerificationStatus.rejected:
                        responseDto.message = $"Your verification request was rejected due " +
                            $"to your domains and business name not matching properly. " +
                            $"{errorMessageEnd}";
                    break;

                    default:
                        businessVerificationModel.errorOccured = true;
                        responseDto.message = $"An unexpected error occured during your " +
                            $"business verification request process. Thus, your request has " +
                            $"not started yet. {errorMessageEnd}";
                    break;
                }

                // Execute writing to Firestore documents and returning a response
                await _firestoreService.SetDocumentByFirestorePath(
                    firestoreUserDocumentPath, userModel);
                await _firestoreService.SetDocumentByFirestorePath(
                    firestoreBusinessVerificationDocumentPath, businessVerificationModel);
                return responseDto;
            }
            // Handle unexpected errors gracefully
            catch (Exception exception)
            {
                // Returning a response
                responseDto.message = $"An unexpected error occured during your " +
                    $"business verification request process. {errorMessageEnd}";
                Console.WriteLine($"Failed process business verification: {exception.Message}");
                return responseDto;
            }
        }
    }
}
