namespace BusinessVerification_Service.Dtos
{
    public class DomainVerificationFirebaseResponseDto
    {
        // Link to Firebase user
        public string UserId { get; set; }

        // If the business name needs to be verified through an admin
        // Initialize to false so that admins do not see verification requests, 
        // where users entered wrong information or unexpected errors occurred, 
        // by default
        public bool RequiresAdmin { get; set; } = false;

        // To be added in future versions that uses email link verification
        // If the user verified through email link
        // public bool EmailVerified { get; set; } = false;

        // Final decision on if the business is verified
        public bool OfficiallyVerified { get; set; } = false;

        // If an error occurred during the verification process
        public bool ErrorOccurred { get; set; } = true;

        // Score from fuzzy comparison
        public int? FuzzyScore { get; set; }

        // Time business requested verification
        // UTC used as Firebase stores timestamps in UTC
        public DateTime RequestedAt { get; set; } = DateTime.UtcNow;

        // Time business verification was approved
        public DateTime? VerifiedAt { get; set; }
    }
}
