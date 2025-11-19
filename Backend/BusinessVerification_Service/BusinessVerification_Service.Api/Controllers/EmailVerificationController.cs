using BusinessVerification_Service.Api.Dtos;
using BusinessVerification_Service.Api.Interfaces.ServicesInterfaces;
using Microsoft.AspNetCore.Mvc;
using System.Web;

namespace BusinessVerification_Service.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EmailVerificationController : ControllerBase
    {
        // Inject dependencies
        private readonly IEmailVerificationService _emailVerificationService;

        // Constructor for dependency injection
        public EmailVerificationController(
            IEmailVerificationService emailVerificationService)
        {
            _emailVerificationService = emailVerificationService;
        }

        // Standard respnose messages
        const string errorMessageEnd = "Request the resending of your verification email in the " +
            "EngagePoint mobile applicaiton. Please ensure all account details are correct " +
            "and try again in a few minutes, contact support if the issue persists.";

        // Bind the verificationToken query parameter to the verificationToken variable
        [HttpGet("verify-email")]
        public async Task<IActionResult> VerifyEmail(
            [FromQuery] string? verificationToken)
        {
            // Create response DTO instance
            BusinessVerificationResponseDto responseDto = new();

            try
            {
                // Call and return the main service business logic
                responseDto = await _emailVerificationService
                    .VerifyEmailVerificaitonToken(verificationToken);
            }
            // Handle unexpected errors gracefully
            catch (Exception exception)
            {
                if (string.IsNullOrWhiteSpace(responseDto.message))
                {
                    responseDto.message = $"An unexpected error occured during your " +
                    $"email verification process. {errorMessageEnd}";
                }
            }
            
            // Redirect to the result page with the message as a query parameter
            return Redirect($"/emailVerificationResult.html?msg={
                HttpUtility.UrlEncode(responseDto.message)}")
            ;
        }
    }
}
