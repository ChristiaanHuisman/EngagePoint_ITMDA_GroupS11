using System.ComponentModel.DataAnnotations;

namespace BusinessVerification_Service.Dtos
{
    public class DomainVerificationRequestDto
    {
        [Required(ErrorMessage = "Please ensure an email address is entered.")]
        [EmailAddress(ErrorMessage = "Please ensure a complete and valid email address is entered.")]
        public string BusinessEmail { get; set; }

        [Required(ErrorMessage = "Please ensure a website address is entered.")]
        public string BusinessWebsite { get; set; }

        [Required(ErrorMessage = "Please ensure a business name is entered.")]
        public string BusinessName { get; set; }
    }
}
