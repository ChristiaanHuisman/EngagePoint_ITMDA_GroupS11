using Google.Cloud.Firestore;

namespace BusinessVerification_Service.Api.Models
{
    // Model representing partial businessVerification document from Firestore
    [FirestoreData]
    public class BusinessVerificationEmailVerificationUpdateModel
    {
        [FirestoreProperty]
        public bool? emailVerified { get; set; }

        // Enum stored as string
        [FirestoreProperty(ConverterType = typeof(
            Services.FirestoreService.FirestoreEnumStringConverter<userVerificationStatus>))]
        public userVerificationStatus verificationStatus { get; set; }
            = userVerificationStatus.notStarted
        ;

        [FirestoreProperty]
        public DateTime? verificationStatusUpdatedAt { get; set; }

        // Helper methods
        public void SetNewPropertyValues(UserEmailVerificationUpdateModel userUpdateModel)
        {
            emailVerified = userUpdateModel.emailVerified;
            verificationStatus = userUpdateModel.verificationStatus;
            verificationStatusUpdatedAt = DateTime.UtcNow;
        }
    }
}
