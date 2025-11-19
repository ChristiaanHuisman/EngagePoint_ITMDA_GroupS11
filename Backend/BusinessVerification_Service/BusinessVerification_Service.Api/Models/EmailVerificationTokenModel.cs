using Google.Cloud.Firestore;

namespace BusinessVerification_Service.Api.Models
{
    // Model representing user document from Firestore
    [FirestoreData]
    public class EmailVerificationTokenModel
    {
        [FirestoreProperty]
        public string? userId { get; set; }

        [FirestoreProperty]
        public string? name { get; set; }

        [FirestoreProperty]
        public string? email { get; set; }

        [FirestoreProperty]
        public DateTime? createdAt { get; set; }

        [FirestoreProperty]
        public DateTime? expiresAt { get; set; }

        // Helper methods
        public void SetTokenTimestamps()
        {
            createdAt = DateTime.UtcNow;
            expiresAt = createdAt.Value.AddHours(24);
        }
    }
}
