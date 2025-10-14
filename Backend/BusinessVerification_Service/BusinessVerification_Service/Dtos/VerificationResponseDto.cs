namespace BusinessVerification_Service.Dtos
{
    public class VerificationResponseDto
    {
        // Assign pending as defualt
        public Status VerificationStatus { get; set; } = Status.Pending;

        // Success or error messages stored here
        // Assign empty as default
        public string Message { get; set; } = string.Empty;
    }

    // Status of business verification process
    public enum Status
    {
        Pending,
        Rejected
    }
}
