using System.Text.Json.Serialization;

namespace BusinessVerification_Service.Dtos
{
    public class VerificationResponseDto
    {
        // Convert enum to string in JSON response
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public Status VerificationStatus { get; set; }

        // Success or error messages stored here
        // Assign empty as default
        public string Message { get; set; } = string.Empty;
    }

    // Status of business verification process
    public enum Status
    {
        NotStarted,
        Rejected,
        AdminPending,
        EmailPending,
        Accepted
    }
}
