namespace BusinessVerification_Service.Dtos
{
    public class VerificationResponseDto
    {
        // Assign Rejected enum option as defualt
        public Status VerificationStatus { get; set; } = Status.Rejected;

        // Success or error messages stored here
        // Assign empty as default
        public string Message { get; set; } = string.Empty;
    }

    // Status of business verification process
    public enum Status
    {
        Rejected,
        Pending,
        Accepted // To be removed in future versions using email link verification
    }
}
