using BusinessVerification_Service.Api.Dtos;
using BusinessVerification_Service.Api.Interfaces.ServicesInterfaces;
using Microsoft.AspNetCore.Mvc;

namespace BusinessVerification_Service.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BusinessVerificationController : ControllerBase
    {
        // Inject dependencies
        private readonly IBusinessVerificationService _businessVerificationService;

        // Constructor for dependency injection
        public BusinessVerificationController(
            IBusinessVerificationService businessVerificationService)
        {
            _businessVerificationService = businessVerificationService;
        }

        // Standard error message ending for displaying user error messages
        const string errorMessageEnd = "Please ensure all account details are correct " +
            "and try again in a few minutes, contact support if the issue persists.";

        // Bind the Authorization header to the authorizationHeader variable
        [HttpGet("request-business-verification")]
        public async Task<IActionResult> RequestBusinessVerification(
            [FromHeader(Name = "Authorization")] string authorizationHeader)
        {
            // Create response DTO instance
            BusinessVerificationResponseDto responseDto = new();

            try
            {
                // Call and return the main service business logic
                responseDto = await _businessVerificationService
                    .BusinessVerificationProcess(authorizationHeader);
                return Ok(responseDto);
            }
            catch
            {
                // Handle unexpected errors gracefully
                responseDto.message = $"An unexpected error occured during your " +
                    $"business verification request process. {errorMessageEnd}";
                return StatusCode(500, responseDto);
            }
        }
    }
}
