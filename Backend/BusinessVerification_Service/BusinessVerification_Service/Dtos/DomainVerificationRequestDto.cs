using System.ComponentModel.DataAnnotations;

namespace BusinessVerification_Service.Dtos
{
    // These properties are sent from the Flutter app and not verified via Firestore, 
    // just to keep read/write operations to a minimum for this prototype,
    // as only the free Firebase plan is used
    public class DomainVerificationRequestDto
    {
        // Automatically passed from the Flutter app
        [Required(ErrorMessage = "Something went wrong, please try again, " + 
            "or contact support if the issue persists.")]
        public string UserId { get; set; }

        // To be added in future versions that uses email link verification
        // If the user verified through email link
        // Automatically passed from the Flutter app
        // [Required(ErrorMessage = "Something went wrong, please try again, " + 
        //     "or contact support if the issue persists.")]
        // public bool EmailVerified { get; set; } = false;

        // Email address from Flutter app
        [Required(ErrorMessage = "Please ensure an email address is entered.")]
        [EmailAddress(ErrorMessage = "Please ensure a complete and valid email address is entered.")]
        public string BusinessEmail { get; set; }

        // Website address from Flutter app
        // URL attribute not used so users have more flexibility,
        // as many users do not include https:// when entering a website address
        [Required(ErrorMessage = "Please ensure a website address is entered.")]
        public string BusinessWebsite { get; set; }

        // Business name from Flutter app
        [Required(ErrorMessage = "Please ensure a business name is entered.")]
        public string BusinessName { get; set; }
    }
}
