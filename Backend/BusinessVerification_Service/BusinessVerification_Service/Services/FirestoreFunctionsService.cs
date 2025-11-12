using BusinessVerification_Service.Dtos;
using BusinessVerification_Service.Interfaces;
using Google.Cloud.Firestore;

namespace BusinessVerification_Service.Services
{
    public class FirestoreFunctionsService : IFirestoreFunctionsService
    {
        // Injected dependencies
        private readonly ILogger<FirestoreFunctionsService> _logger;
        private readonly FirestoreDb _firestoreDb;

        // Constructor for dependency injection
        public FirestoreFunctionsService(ILogger<FirestoreFunctionsService> logger, 
            FirestoreDb firestoreDb)
        {
            _logger = logger;
            _firestoreDb = firestoreDb;
        }

        // Firestore collection names
        const string firestoreUsersCollection = "users";
        const string usersBusinessVerificationCollection = "businessVerification";

        // Writes business verification data to Firestore
        // Dictionaries are used for merging fields,
        // as it gives more control compared to using a DTO object directly
        public async Task WriteVerificationRequest(
            DomainVerificationFirebaseResponseDto firestoreRequestDto)
        {
            // Extract variables from Firebase response DTO, 
            // just for easier use
            string userId = firestoreRequestDto.UserId;
            bool requiresAdminVerification = firestoreRequestDto.RequiresAdminVerification;
            bool officiallyVerified = firestoreRequestDto.OfficiallyVerified;
            bool errorOccurred = firestoreRequestDto.ErrorOccurred;
            int? fuzzyScore = firestoreRequestDto.FuzzyScore;
            DateTime verificationRequestedAt = firestoreRequestDto.VerificationRequestedAt;
            // To be removed in future versions that uses email link verification
            DateTime? verifiedAt = firestoreRequestDto.VerifiedAt;

            // Ensure userId is not null or empty
            if (string.IsNullOrWhiteSpace(userId))
            {
                _logger.LogError(
                    "Service: UserId property cannot be null or empty when " + 
                    "writing verification request to Firestore."
                );
                throw new ArgumentException(
                    "User document ID cannot be empty when writing the business verification request " +
                    "to the database."
                );
            }

            _logger.LogInformation(
                "Service: Received user {user} DomainVerificationFirebaseResponseDto with " + 
                "the following properties for writing the verification request to Firebase:\n" + 
                "RequiresAdminVerification: {requiresAdminVerification}\n" +
                "OfficiallyVerified: {officiallyVerified}\n" + 
                "ErrorOccurred: {errorOccurred}\n" + 
                "FuzzyScore: {fuzzyScore}\n" + 
                "VerificationRequestedAt: {verificationRequestedAt}\n" + 
                "VerifiedAt: {verifiedAt}", 
                userId, requiresAdminVerification, officiallyVerified, errorOccurred, fuzzyScore, 
                verificationRequestedAt, verifiedAt
            );

            // Wrapper safety try catch block for the entire method
            try
            {
                // Get the reference to the user document in Firestore
                var documentReference = _firestoreDb.Collection(
                    firestoreUsersCollection).Document(userId);

                // Map the relavent user document fields
                // These fields are selceted for query efficiency for Firestore operations
                Dictionary<string, object> merge = new Dictionary<string, object>
                {
                    {"requiresAdminVerification", requiresAdminVerification}, 
                    {"officiallyVerified", officiallyVerified}, 
                    {"verificationRequestedAt", verificationRequestedAt}
                };

                // Use MergeAll for best Firestore merging functionality
                await documentReference.SetAsync(merge, SetOptions.MergeAll);

                _logger.LogInformation(
                    "Service: Wrote user document {user} properties to Firestore successfully.",
                    userId
                );

                // Reference the verification subcollection
                // There should only be one document of this subcollection per user
                documentReference = documentReference.Collection(
                    usersBusinessVerificationCollection).Document(userId);

                // Map the relavent verification document fields
                // These fields are selceted for data completeness
                merge = new Dictionary<string, object>
                {
                    {"requiresAdminVerification", requiresAdminVerification}, 
                    {"officiallyVerified", officiallyVerified}, 
                    {"errorOccurred", errorOccurred}, 
                    {"fuzzyScore", fuzzyScore}, 
                    {"verificationRequestedAt", verificationRequestedAt}, 
                    {"verifiedAt", verifiedAt}
                };

                // Use MergeAll for best Firestore merging functionality
                await documentReference.SetAsync(merge, SetOptions.MergeAll);

                _logger.LogInformation(
                    "Service: Wrote business verification document properties " + 
                    "of user document {user} to Firestore successfully.",
                    userId
                );

                _logger.LogInformation(
                    "Service: Wrote all verification request properties " +
                    "of user document {user} to Firestore successfully.",
                    userId
                );
            }
            // Handle errors
            catch (ArgumentException)
            {
                throw;
            }
            catch (Exception exception)
            {
                _logger.LogError(exception, 
                    "Service: Unexpected fail of writing certain or all business verification data " + 
                    "to user document {user}.", 
                    userId
                );
                throw;
            }
        }
    }
}
