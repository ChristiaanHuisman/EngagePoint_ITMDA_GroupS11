using Google.Cloud.Firestore;

namespace BusinessVerification_Service.Api.Models
{
    // Model representing user document from Firestore
    [FirestoreData]
    public class UserModel
    {
        public UserModel() { }

        [FirestoreProperty]
        public string? name { get; set; }

        [FirestoreProperty]
        public string? email { get; set; }

        [FirestoreProperty]
        public string? website { get; set; }

        // Enum stored as string
        [FirestoreProperty(ConverterType = typeof(
            Services.FirestoreService.FirestoreEnumStringConverter<userRole>))]
        public userRole role { get; set; } = userRole.customer;

        // Enum stored as string
        [FirestoreProperty(ConverterType = typeof(
            Services.FirestoreService.FirestoreEnumStringConverter<userVerificationStatus>))]
        public userVerificationStatus verificationStatus { get; set; }
            = userVerificationStatus.notStarted
        ;

        [FirestoreProperty]
        public DateTime? verificationRequestedAt { get; set; }

        [FirestoreProperty]
        public bool emailVerified { get; set; } = false;
    }

    // Enums
    public enum userRole
    {
        customer,
        business,
        admin
    }

    public enum userVerificationStatus
    {
        notStarted,
        pendingAdmin,
        pendingEmail,
        rejected,
        accepted
    }
}
