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

        // Constructor for dependency injection of logger and service
        public DomainVerificationController(ILogger<DomainVerificationController> logger, 
            IDomainVerificationService domainVerificationService)
        {
            _logger = logger;
            _domainVerificationService = domainVerificationService;
        }

        // API call for veryfying the user input domains match,
        // matches user input to DTO properties
        [HttpPost("verify")]
        public async Task<IActionResult> VerifyDomain([FromBody] DomainVerificationRequestDto requestDto)
        {
            // Wrapper safety try block for the entire action
            try
            {
                // Check if model binded to DTO successfully
                // Should not be needed as no attributes are used in the DTO
                /*if (!ModelState.IsValid)
                {
                    // Get all errors from the ModelState
                    var errors = string.Join("; ", 
                        ModelState.Values
                        .SelectMany(propertyState => propertyState.Errors)
                        .Select(error => error.ErrorMessage)
                    );

                    // Handle DTO binding errors
                    _logger.LogWarning(
                        "Controller: Invalid request received with errors: {errors}", 
                        errors
                    );

                    // Return response DTO
                    return BadRequest(new VerificationResponseDto
                    {
                        Match = false,
                        Message = "Something unexpectd went wrong with the verification request. " +
                        "Please ensure all details are entered correctly and try again, " +
                        "or contact support if the issue persists."
                    });
                }*/

                _logger.LogInformation(
                    "Controller: Domain verification request for email {email} and website {website} recieved.",
                    requestDto.BusinessEmail, requestDto.BusinessWebsite
                );

                // Use service method to check if the domains of user input matches
                bool returnResult = _domainVerificationService.VerifyDomainMatch(
                    requestDto.BusinessEmail, requestDto.BusinessWebsite
                );

                // Return if it is a match if no errors occur
                _logger.LogInformation(
                    "Controller: Return domain verification response for email {email} and website {website} " +
                    "with result {result}.",
                    requestDto.BusinessEmail, requestDto.BusinessWebsite, returnResult
                );
                return Ok(
                    new VerificationResponseDto
                    {
                        Match = returnResult, 
                        Message = returnResult 
                        ? "Business domain verification was successful." 
                        : "The email and website domain provided does not match."
                    }
                );
            }
            // Handle errors
            catch (ApplicationException exception)
            {
                _logger.LogInformation(
                    "Controller: Return domain verification response for email {email} and website {website} " +
                    "with error message.",
                    requestDto.BusinessEmail, requestDto.BusinessWebsite
                );
                return StatusCode(500, 
                    new VerificationResponseDto
                    {
                        Match = false,
                        Message = exception.Message
                    }
                );
            }
            catch (Exception exception)
            {
                _logger.LogInformation(
                    "Controller: Return domain verification response for email {email} and website {website} " +
                    "with error message.",
                    requestDto.BusinessEmail, requestDto.BusinessWebsite
                );
                return BadRequest(
                    new VerificationResponseDto
                    {
                        Match = false,
                        Message = exception.Message
                    }
                );
            }
        }
    }
}
