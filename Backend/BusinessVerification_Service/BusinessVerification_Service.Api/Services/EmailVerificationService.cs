using BusinessVerification_Service.Api.Dtos;
using BusinessVerification_Service.Api.Interfaces.HelpersInterfaces;
using BusinessVerification_Service.Api.Interfaces.ServicesInterfaces;
using BusinessVerification_Service.Api.Models;
using System.Text.RegularExpressions;

namespace BusinessVerification_Service.Api.Services
{
    public class EmailVerificationService : IEmailVerificationService
    {
        // Inject dependencies
        private readonly string _baseUrl;
        private readonly ITokenGeneratorHelper _tokenGeneratorHelper;
        private readonly IEmailHelper _emailHelper;
        private readonly IFirestoreService _firestoreService;
        private readonly INormalizationAndValidationHelper _normalizationAndValidationHelper;

        // Constructor for dependency injection
        public EmailVerificationService(ServiceInformationModel serviceInformationModel,
            ITokenGeneratorHelper tokenGeneratorHelper,
            IEmailHelper emailHelper,
            IFirestoreService firestoreService,
            INormalizationAndValidationHelper normalizationAndValidationHelper)
        {
            _baseUrl = serviceInformationModel.baseUrl;
            _tokenGeneratorHelper = tokenGeneratorHelper;
            _emailHelper = emailHelper;
            _firestoreService = firestoreService;
            _normalizationAndValidationHelper = normalizationAndValidationHelper;
        }

        // Standard respnose messages
        const string errorMessageEnd = "Request the resending of your verification email in the " +
            "EngagePoint mobile applicaiton. Please ensure all account details are correct " +
            "and try again in a few minutes, contact support if the issue persists.";
        const string resentVerificationEmailMessage = "Please look out for the resent verification " +
            "email with the new verification link. It might take a few minutes to reflect in your " +
            "inbox. Email address used: ";

        // Collection names in Firestore
        const string emailVerificationTokenCollection = "emailVerificationTokens";
        const string userCollection = "users";
        const string verificationCollection = "businessVerification";

        // Field names in Firestore documents
        const string userIdField = "userId";

        // When a user requests a verification email that has not requested one before, the
        // method receives the relevant UserModel and userId
        public async Task NewVerificationEmail(UserModel userModel, string userId)
        {
            // Create EmailVerificationTokenModel
            EmailVerificationTokenModel tokenModel = new()
            {
                userId = userId,
                name = userModel.name,
                email = userModel.email,
            };
            tokenModel.SetTokenTimestamps();

            // Send the verification email
            await SendVerificationEmailProcess(tokenModel);
        }

        // When a user requests to resend a verification email, the method receives
        // the relevant old EmailVerificationTokenModel and token self
        public async Task ResendVerificationEmail(EmailVerificationTokenModel oldTokenModel,
            string oldVerificationToken)
        {
            // Create new EmailVerificationTokenModel
            EmailVerificationTokenModel tokenModel = new()
            {
                userId = oldTokenModel.userId,
                name = oldTokenModel.name,
                email = oldTokenModel.email,
            };
            tokenModel.SetTokenTimestamps();

            // Get relevant Firebase document paths
            string firestoreEmailVerificationTokenDocumentPath =
                $"{emailVerificationTokenCollection}/{oldVerificationToken}";

            // // Send the verification email
            await SendVerificationEmailProcess(tokenModel);

            // Delete old email verification token from Firestore
            await _firestoreService.DeleteDocumentFromFirestore(
                firestoreEmailVerificationTokenDocumentPath);
        }

        // Process of sending a verification email upon request, receives
        // an EmailVerificationTokenModel
        //
        // The method is set as an async Task and not void so that errors
        // can be propogated correctly
        public async Task SendVerificationEmailProcess(EmailVerificationTokenModel tokenModel)
        {
            try
            {
                // Generate verification token
                string verificationToken = _tokenGeneratorHelper.GenerateToken();

                // Build link
                string verificationLink =
                    $"{_baseUrl}/api/EmailVerification/verify-email?verificationToken={verificationToken}";

                // Build email content
                string emailSubject = "Verify your EngagePoint account email address";
                string emailHtml = _emailHelper.BuildVerificationEmailHtml(
                    tokenModel.name, verificationLink);

                // Send email via SMTP
                await _emailHelper.SendEmailSmtp(tokenModel.email, tokenModel.name,
                    emailSubject, emailHtml);

                // Get relevant Firebase document paths
                string firestoreEmailVerificationTokenDocumentPath =
                    $"{emailVerificationTokenCollection}/{verificationToken}";

                // Write EmailVerificationTokenModel to Firestore
                await _firestoreService.SetDocumentByFirestorePath(
                    firestoreEmailVerificationTokenDocumentPath, tokenModel);
            }
            // Log error
            catch (Exception exception)
            {
                Console.WriteLine($"Failed to send verification email: {exception.Message}");
                throw;
            }
        }

        // Process of verifying the email verification token when a user clicks on the verification
        // link, receives the verification token and returns a message to display to the user
        public async Task<BusinessVerificationResponseDto> VerifyEmailVerificaitonToken(
            string? verificationToken)
        {
            // Create response DTO instance
            BusinessVerificationResponseDto responseDto = new();

            try
            {
                // Check for missing verification token
                verificationToken = verificationToken?.Trim();
                if (string.IsNullOrWhiteSpace(verificationToken))
                {
                    // Returning a response
                    responseDto.message = $"Unverified link. " +
                        $"{errorMessageEnd}";
                    return responseDto;
                }

                // Get relevant Firebase document paths
                string firestoreEmailVerificationTokenDocumentPath =
                    $"{emailVerificationTokenCollection}/{verificationToken}";

                // Retrieve documents from Firestore and convert to relevant models
                EmailVerificationTokenModel? tokenModel = await _firestoreService
                    .GetDocumentFromFirestore<EmailVerificationTokenModel>(
                    firestoreEmailVerificationTokenDocumentPath);
                if (tokenModel == null)
                {
                    // Returning a response
                    responseDto.message = $"Could not find verification token in database. " +
                        $"{errorMessageEnd}";
                    return responseDto;
                }

                // Validate data exists
                if (!_normalizationAndValidationHelper.IsPopulated(
                    tokenModel.userId, tokenModel.name, tokenModel.email, tokenModel.createdAt,
                    tokenModel.expiresAt))
                {
                    // Returning a response
                    responseDto.message = $"Some user data is missing. {errorMessageEnd}";
                    return responseDto;
                }

                // Normalize data
                tokenModel.email = _normalizationAndValidationHelper.NormalizeString(
                    tokenModel.email);
                tokenModel.email = _normalizationAndValidationHelper.RemoveAllWhitespace(
                    tokenModel.email);
                tokenModel.userId = tokenModel.userId.Trim();
                tokenModel.userId = _normalizationAndValidationHelper.RemoveAllWhitespace(
                    tokenModel.userId);
                tokenModel.name = tokenModel.name.Trim();
                tokenModel.name = Regex.Replace(tokenModel.name, @"\s+", " ");
                tokenModel.name = tokenModel.name.Trim().Trim('.', ',', ';', ':', '!', '?', '/', '\\', '@');

                // Validate email format
                if (!_normalizationAndValidationHelper.IsValidEmailAddress(tokenModel.email))
                {
                    // Returning a response
                    responseDto.message = $"Invalid email address in database. {errorMessageEnd}";
                    return responseDto;
                }

                // Check if the verification token has expired
                if (DateTime.UtcNow > tokenModel.expiresAt)
                {
                    // Automatically resend verification email
                    await ResendVerificationEmail(tokenModel, verificationToken);

                    // Returning a response
                    responseDto.message = $"Your verification link has expired. A new one has " +
                        $"been created automatically. {resentVerificationEmailMessage}{tokenModel.email}";
                    return responseDto;
                }

                // Get relevant Firebase document paths
                string firestoreUserDocumentPath = $"{userCollection}/{tokenModel.userId}";
                string firestoreBusinessVerificationDocumentPath = $"{userCollection}/" +
                    $"{tokenModel.userId}/{verificationCollection}/{tokenModel.userId}";

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

                // Check if user email is already verified
                if (userModel.emailVerified)
                {
                    // Returning a response
                    responseDto.message = $"You already had a successful email verification " +
                        $"process previously.";
                    return responseDto;
                }

                // Check that the user details align with the verification token details
                if (tokenModel.email != userModel.email)
                {
                    // Returning a response
                    responseDto.message = $"User details do not align with verification " +
                        $"token details. {errorMessageEnd}";
                    return responseDto;
                }

                // Retrieve documents from Firestore and convert to relevant models
                BusinessVerificationModel? businessVerificationModel = await
                    _firestoreService.GetDocumentFromFirestore<BusinessVerificationModel>(
                    firestoreBusinessVerificationDocumentPath);
                businessVerificationModel ??= new();

                // Create update models and set new property values
                UserEmailVerificationUpdateModel userUpdateModel = new();
                BusinessVerificationEmailVerificationUpdateModel businessVerificationUpdateModel = new();

                // If else statements are used and not a switch case as some conditions
                // require multiple checks
                //
                // Business verification cannot be completed until a user email is verified
                //
                // Set new property values for update models and assign their appropriate
                // response messages
                if (userModel.role == userRole.business
                    && businessVerificationModel.fuzzyScore >= 90)
                {
                    // Businesses that already pass business verification checks
                    userUpdateModel.verificationStatus = userVerificationStatus.accepted;
                    responseDto.message = $"Your email address and business " +
                        $"verification was successful.";
                }
                else if (userModel.role == userRole.business
                    && businessVerificationModel.fuzzyScore == null)
                {
                    // Businesses that have not yet undergone business verification checks
                    userUpdateModel.verificationStatus = userVerificationStatus.notStarted;
                    responseDto.message = $"Your email address verification was successful. " +
                        $"However, you still need to request business verification in the " +
                        $"EngagePoint mobile applicaiton.";
                }
                else if (userModel.role == userRole.business
                    && (userModel.verificationStatus == userVerificationStatus.rejected
                    || businessVerificationModel.fuzzyScore <= 59))
                {
                    // Businesses that have failed business verification checks
                    userUpdateModel.verificationStatus = userVerificationStatus.rejected;
                    responseDto.message = $"Your email address verification was successful. " +
                        $"However, you still need to request new business verification in the " +
                        $"EngagePoint mobile applicaiton.";
                }
                else if (userModel.role == userRole.business)
                {
                    // Businesses that still need admin review
                    userUpdateModel.verificationStatus = userVerificationStatus.pendingAdmin;
                    responseDto.message = $"Your email address verification was successful. " +
                        $"Just wait on admin approval for you business verification now.";
                }
                else if (userModel.role == userRole.customer)
                {
                    // Customers are automatically accepted upon email verification
                    userUpdateModel.verificationStatus = userVerificationStatus.accepted;
                    responseDto.message = $"Your email address verification was successful.";
                }
                else if (userModel.role == userRole.admin)
                {
                    // Admins are automatically accepted upon email verification
                    userUpdateModel.verificationStatus = userVerificationStatus.accepted;
                    responseDto.message = $"Your email address verification was successful.";
                }
                else
                {
                    // Returning a response
                    responseDto.message = $"Unknown user role or status. {errorMessageEnd}";
                    return responseDto;
                }
                userUpdateModel.emailVerified = true;
                businessVerificationUpdateModel.SetNewPropertyValues(userUpdateModel);

                // Execute writing to Firestore documents
                await _firestoreService.SetDocumentByFirestorePath(
                    firestoreUserDocumentPath, userUpdateModel);
                await _firestoreService.SetDocumentByFirestorePath(
                    firestoreBusinessVerificationDocumentPath, businessVerificationUpdateModel);

                // Delete all email verification tokens for the user
                await _firestoreService.DeleteDocumentsFromCollectionByField(
                    emailVerificationTokenCollection, userIdField, tokenModel.userId);

                // Returning a response
                return responseDto;
            }
            // Handle unexpected errors gracefully
            catch (Exception exception)
            {
                // Returning a response
                responseDto.message = $"An unexpected error occured during your " +
                    $"email verification process. {errorMessageEnd}";
                Console.WriteLine($"Failed process email verification: {exception.Message}");
                return responseDto;
            }
        }
    }
}
