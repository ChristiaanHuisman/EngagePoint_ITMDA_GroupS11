namespace BusinessVerification_Service.Models
{
    public class DomainVerificationModel
    {
        public string UserId { get; set; }
        public string BusinessEmail { get; set; }
        public string BusinessWebsite { get; set; }
        public string BusinessName { get; set; }
        public string VerificationMethod { get; set; } // e.g. domain
    }
}
