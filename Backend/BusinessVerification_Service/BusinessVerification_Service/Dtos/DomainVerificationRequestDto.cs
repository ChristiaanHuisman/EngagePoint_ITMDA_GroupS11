namespace BusinessVerification_Service.Dtos
{
    public class DomainVerificationRequestDto
    {
        // VerifyDomainMatch already contain these error checks and handles it gracefully,
        // although this approach would probably be easier
        // [Required(ErrorMessage = "Email address is required.")]
        // [EmailAddress(ErrorMessage = "Email address must be a valid email address.")]
        public string BusinessEmail { get; set; }

        // VerifyDomainMatch already contain these error checks and handles it gracefully,
        // although this approach would probably be easier
        // [Required(ErrorMessage = "Website address is required.")]
        // [Url(ErrorMessage = "Website address must be a valid URL.")]
        public string BusinessWebsite { get; set; }
    }
}
