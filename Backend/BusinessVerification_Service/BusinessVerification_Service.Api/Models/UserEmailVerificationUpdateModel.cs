using Google.Cloud.Firestore;

namespace BusinessVerification_Service.Api.Models
{
    // Model representing partial user document from Firestore
    [FirestoreData]
    public class UserEmailVerificationUpdateModel
    {
        [FirestoreProperty]
        public bool emailVerified { get; set; } = false;

        // Enum stored as string
        [FirestoreProperty(ConverterType = typeof(
            Services.FirestoreService.FirestoreEnumStringConverter<userVerificationStatus>))]
        public userVerificationStatus verificationStatus { get; set; }
            = userVerificationStatus.notStarted
        ;
    }
}
