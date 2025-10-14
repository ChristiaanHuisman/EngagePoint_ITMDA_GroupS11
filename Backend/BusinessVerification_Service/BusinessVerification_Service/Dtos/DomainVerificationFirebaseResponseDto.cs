namespace BusinessVerification_Service.Dtos
{
    public class DomainVerificationFirebaseResponseDto
    {
        // Link to Firebase user
        public string UserId { get; set; }

        // If the business name needs to be verified through an admin
        public bool RequiresAdmin { get; set; } = true;

        // If the user verified through email link
        public bool EmailVerified { get; set; } = false;

        // Time business requested verification
        public DateTime RequestedAt { get; set; } = DateTime.UtcNow;

        // Time business verification was approved
        public DateTime? VerifiedAt { get; set; }

        // Score from fuzzy comparison
        public int? FuzzyScore { get; set; }
    }
}
