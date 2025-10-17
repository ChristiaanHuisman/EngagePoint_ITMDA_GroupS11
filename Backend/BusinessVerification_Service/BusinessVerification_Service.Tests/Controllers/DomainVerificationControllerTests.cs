/*using BusinessVerification_Service.Controllers;
using BusinessVerification_Service.Dtos;
using BusinessVerification_Service.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace BusinessVerification_Service.Tests.Controllers
{
    // Test to independently verify the DomainVerificationController,
    // seperate from the service layer
    [Trait("Category", "DomainVerificationController Tests")]
    public class DomainVerificationControllerTests
    {
        // Helper method to create a controller instance with mocked dependencies
        private DomainVerificationController CreateController(Exception exceptionToThrow = null, 
            bool? serviceResult = null)
        {
            // Mock the service for domain verification
            var mockService = new Mock<IDomainVerificationService>();

            // Setup the mock to throw an exception or return a result based on parameters
            if (exceptionToThrow != null)
            {
                // Throw exception to test controller error handling
                mockService.Setup(service => service.VerifyDomainMatch(
                    It.IsAny<string>(), 
                    It.IsAny<string>()
                )).Throws(exceptionToThrow);
            }
            else if (serviceResult.HasValue)
            {
                // Return value to test controller normal operations
                mockService.Setup(service => service.VerifyDomainMatch(
                    It.IsAny<string>(), 
                    It.IsAny<string>()
                )).Returns(serviceResult.Value);
            }

            // Use NullLogger for testing purposes that won't log anything
            var logger = NullLogger<DomainVerificationController>.Instance;

            // Return the controller
            return new DomainVerificationController(logger, mockService.Object);
        }

        // Test true response from VerifyDomainMatch
        [Fact]
        public async Task VerifyDomain_DomainsMatch_ReturnsOk()
        {
            // Arrange
            var controller = CreateController(serviceResult: true);

            // Prepare
            var requestDto = new DomainVerificationRequestDto
            {
                BusinessEmail = "person@example.com", 
                BusinessWebsite = "https://example.com"
            };

            // Act
            var result = await controller.VerifyDomain(requestDto);

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(result);

            // Ensure controller returns a DTO as response
            var responseDto = Assert.IsType<VerificationResponseDto>(okResult.Value);

            // Assert
            Assert.True(responseDto.Match);
            Assert.Equal("Business domain verification was successful.", responseDto.Message);
        }

        // Test false response from VerifyDomainMatch
        [Fact]
        public async Task VerifyDomain_DomainsNoMatch_ReturnsOk()
        {
            // Arrange
            var controller = CreateController(serviceResult: false);

            // Prepare
            var requestDto = new DomainVerificationRequestDto
            {
                BusinessEmail = "person@example.com", 
                BusinessWebsite = "https://different.com"
            };

            // Act
            var result = await controller.VerifyDomain(requestDto);

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(result);

            // Ensure controller returns a DTO as response
            var responseDto = Assert.IsType<VerificationResponseDto>(okResult.Value);

            // Assert
            Assert.False(responseDto.Match);
            Assert.Equal("The email and website domain provided does not match.", responseDto.Message);
        }

        // Test ArgumentException response from VerifyDomainMatch
        [Fact]
        public async Task VerifyDomain_ArgumentExceptionThrown_ReturnsBadRequest()
        {
            // Arrange
            var controller = CreateController(
                exceptionToThrow: new ArgumentException("Invalid input."));

            // Prepare
            var requestDto = new DomainVerificationRequestDto
            {
                BusinessEmail = "invalid_email", 
                BusinessWebsite = "invalid_website"
            };

            // Act
            var result = await controller.VerifyDomain(requestDto);

            // Assert
            var badRequest = Assert.IsType<BadRequestObjectResult>(result);

            // Ensure controller returns a DTO as response
            var responseDto = Assert.IsType<VerificationResponseDto>(badRequest.Value);

            // Assert
            Assert.False(responseDto.Match);
            Assert.Equal("Invalid input.", responseDto.Message);
        }

        // Test ApplicationException response from VerifyDomainMatch
        [Fact]
        public async Task VerifyDomain_ApplicationExceptionThrown_ReturnsInternalServerError()
        {
            // Arrange
            var controller = CreateController(
                exceptionToThrow: new ApplicationException("Unexpected error."));

            // Prepare
            var requestDto = new DomainVerificationRequestDto
            {
                BusinessEmail = "person@example.com", 
                BusinessWebsite = "https://example.com"
            };

            // Act
            var result = await controller.VerifyDomain(requestDto);

            // Assert
            var objectResult = Assert.IsType<ObjectResult>(result);
            Assert.Equal(500, objectResult.StatusCode);

            // Ensure controller returns a DTO as response
            var responseDto = Assert.IsType<VerificationResponseDto>(objectResult.Value);

            // Assert
            Assert.False(responseDto.Match);
            Assert.Equal("Unexpected error.", responseDto.Message);
        }
    }
}*/
