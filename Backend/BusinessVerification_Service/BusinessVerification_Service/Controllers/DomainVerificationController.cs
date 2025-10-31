using BusinessVerification_Service.Dtos;
using BusinessVerification_Service.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BusinessVerification_Service.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DomainVerificationController : ControllerBase
    {
        // Injected dependencies
        private readonly ILogger<DomainVerificationController> _logger;
        private readonly IDomainVerificationService _domainVerificationService;

        // Constructor for dependency injection
        public DomainVerificationController(ILogger<DomainVerificationController> logger, 
            IDomainVerificationService domainVerificationService)
        {
            _logger = logger;
            _domainVerificationService = domainVerificationService;
        }
        
        // API call for veryfying the user input domains and business name match, 
        // matches user input to DTO properties
        [HttpPost("requestverify")]
        public async Task<IActionResult> VerifyBusiness(
            [FromBody] DomainVerificationRequestDto verificationRequestDto)
        {
            // Initialize response DTO
            VerificationResponseDto returnResponse = new VerificationResponseDto();

            // Check if model binded to DTO successfully
            if (!ModelState.IsValid)
            {
                // Get errors from the ModelState
                var errors = string.Join("\n",
                    ModelState.Values
                    .SelectMany(propertyState => propertyState.Errors)
                    .Select(error => error.ErrorMessage)
                );

                _logger.LogError(
                    "Controller: Invalid request DTO received from user {user} with errors:\n{errors}",
                    verificationRequestDto.UserId, errors
                );

                // Return response DTO with error message
                returnResponse.Message = "Please ensure all details are entered correctly and try again, " + 
                    "contact support if the issue persists.";
                return UnprocessableEntity(returnResponse);
            }

            // Extract variables from request DTO, 
            // just for easier usage in the action
            string userId = verificationRequestDto.UserId;
            string email = verificationRequestDto.BusinessEmail;
            string website = verificationRequestDto.BusinessWebsite;
            string name = verificationRequestDto.BusinessName;

            _logger.LogInformation(
                "Controller: Domain verification request for user {user} with email {email}, " +
                "website {website} and business name {name} recieved.",
                userId, email, website, name
            );

            // Wrapper safety try catch block for the action calling the service method
            try
            {
                // Use service method to check if the domains of user input matches
                returnResponse = _domainVerificationService.VerifyBusiness(
                    verificationRequestDto
                );
            }
            // Handle errors throwing appropriate custom error message
            catch (Exception exception)
            {
                _logger.LogError(exception,
                    "Controller: Unexpected error during domain verification for user {user}.",
                    userId
                );

                // Return response DTO with error message
                returnResponse.Message = "Business verification failed unexpectedly. " +
                    "Please ensure all details are entered correctly and try again, " +
                    "contact support if the issue persists.";
                return StatusCode(500, returnResponse);
            }

            _logger.LogInformation(
                "Controller: Return domain verification response for user {user} with email {email}, " +
                "website {website}, business name {name} and a status of {status}.",
                userId, email, website, name, returnResponse.VerificationStatus
            );

            // Return the response DTO
            return Ok(returnResponse);
        }
    }
}
