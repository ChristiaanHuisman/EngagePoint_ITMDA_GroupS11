using Google.Cloud.Firestore;

namespace BusinessVerification_Service.Api.Models
{
    // Model representing businessVerification document from Firestore
    [FirestoreData]
    public class BusinessVerificationModel
    {
        public BusinessVerificationModel() { }

        [FirestoreProperty]
        public int attemptNumber { get; set; } = 0;

        [FirestoreProperty]
        public bool? errorOccured { get; set; }

        [FirestoreProperty]
        public bool? emailVerified { get; set; }

        // Enum stored as string
        [FirestoreProperty(ConverterType = typeof(
            Services.FirestoreService.FirestoreEnumStringConverter<userVerificationStatus>))]
        public userVerificationStatus verificationStatus { get; set; }
            = userVerificationStatus.notStarted;

        [FirestoreProperty]
        public int? fuzzyScore { get; set; }

        [FirestoreProperty]
        public DateTime? verificationRequestedAt { get; set; }

        [FirestoreProperty]
        public DateTime? verificationStatusUpdatedAt { get; set; }

        // Helper methods
        public void SetVerificationStatus(UserModel userModel)
        {
            verificationStatus = userModel.verificationStatus;
            verificationStatusUpdatedAt = DateTime.UtcNow;
        }

        public void SetEmailVerified(UserModel userModel)
        {
            emailVerified = userModel.emailVerified;
        }

        public void SetVerificationRequestedAt(UserModel userModel)
        {
            verificationRequestedAt = userModel.verificationRequestedAt;
        }
    }
}
