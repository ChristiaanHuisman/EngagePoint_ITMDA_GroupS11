using System.Text.Json.Serialization;

namespace BusinessVerification_Service.Dtos
{
    public class VerificationResponseDto
    {
        // Assign NotStarted enum option as defualt
        // Convert enum to string in JSON response
        [JsonConverter(typeof(JsonStringEnumConverter))]
        public Status VerificationStatus { get; set; } = Status.NotStarted;

        // Success or error messages stored here
        // Assign empty as default
        public string Message { get; set; } = string.Empty;
    }

    // Status of business verification process
    public enum Status
    {
        NotStarted,
        Rejected,
        Pending,
        Accepted // To be removed in future versions that uses email link verification
    }
}
