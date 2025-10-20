using System.Text.Json.Serialization;

namespace BusinessVerification_Service.Dtos
{
    public class DomainVerificationFirebaseResponseDto
    {
        // Link to Firebase user
        public string UserId { get; set; }

        // Status of business verification process
        // Pending status indicates that admin review is required
        // Convert enum to string in JSON response
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public Status VerificationStatus { get; set; }

        // To be added in future versions that uses email link verification
        // If the user verified through email link
        // public bool EmailVerified { get; set; } = false;

        // If an error occurred during the verification process
        public bool ErrorOccurred { get; set; } = true;

        // Score from fuzzy comparison
        public int? FuzzyScore { get; set; }

        // Time business requested verification
        // UTC used as Firestore saves timestamps in UTC
        public DateTime VerificationRequestedAt { get; set; } = DateTime.UtcNow;

        // To be removed in future versions that uses email link verification
        // Time business verification was approved
        public DateTime? VerificationDecidedAt { get; set; }
    }
}
