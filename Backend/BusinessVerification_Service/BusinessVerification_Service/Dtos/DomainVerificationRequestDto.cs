using System.ComponentModel.DataAnnotations;

namespace BusinessVerification_Service.Dtos
{
    public class DomainVerificationRequestDto
    {
        // Automatically passed via flutter app
        [Required(ErrorMessage = "Something went wrong, please try again, " + 
            "or contact support if the issue persists.")]
        public string UserId { get; set; }

        // Email address from flutter app
        [Required(ErrorMessage = "Please ensure an email address is entered.")]
        [EmailAddress(ErrorMessage = "Please ensure a complete and valid email address is entered.")]
        public string BusinessEmail { get; set; }

        // Website address from flutter app
        // URL attribute not used so users have more flexibility,
        // as many users do not include https:// when entering a website address
        [Required(ErrorMessage = "Please ensure a website address is entered.")]
        public string BusinessWebsite { get; set; }

        // Business name from flutter app
        [Required(ErrorMessage = "Please ensure a business name is entered.")]
        public string BusinessName { get; set; }
    }
}
