using BusinessVerification_Service.Controllers;
using BusinessVerification_Service.Dtos;
using BusinessVerification_Service.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;

namespace BusinessVerification_Service.Tests.Controllers
{
    // Independently testing the DomainVerificationController,
    // seperate from the service layer
    [Trait("Category", "DomainVerificationController Tests")]
    public class DomainVerificationControllerTests
    {
        // Injected dependencies
        private readonly Mock<ILogger<DomainVerificationController>> _mockLogger;
        private readonly Mock<IDomainVerificationService> _mockService;

        // Constructor for dependency injection
        public DomainVerificationControllerTests()
        {
            _mockLogger = new Mock<ILogger<DomainVerificationController>>();
            _mockService = new Mock<IDomainVerificationService>();
        }

        // Helper method to create the controller
        private DomainVerificationController CreateController()
        {
            return new DomainVerificationController(_mockLogger.Object, _mockService.Object);
        }

        // Helper method for loggin verification
        private void VerifyLog(LogLevel logLevel)
        {
            _mockLogger.Verify(logger => logger.Log(
                logLevel, // Expect a specific log level 
                It.IsAny<EventId>(), // Do not care about a specific event 
                It.IsAny<It.IsAnyType>(), // Do not care about the state parameter 
                It.IsAny<Exception>(), // Do not care about the exception parameter 
                // Do not care about the formatter function
                (Func<It.IsAnyType, Exception?, string>)It.IsAny<object>()), 
                Times.Once // Ensure logging was called only once
            );
        }

        // This test has extensive comments,
        // the following tests will have less comments,
        // as it follows the same structure
        // If following tests need more explanation, 
        // it will be commented accordingly
        // Logs will only be verified for non success outcomes
        // Test when the request DTO is invalid
        // Should return UnprocessableEntity
        [Fact]
        public async Task VerifyBusiness_InvalidDto_ReturnsUnprocessableEntity()
        {
            // Arrange
            // Create the controller instance
            DomainVerificationController controller = CreateController();
            // Force model behaviour
            controller.ModelState.AddModelError("UserId", "Required.");
            // Create the received request DTO
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto();

            // Act
            // Call the service method with the test DTO
            var actionResult = await controller.VerifyBusiness(requestDto);

            // Assert
            // Get the ActionResult type if it is the expected type
            var unprocessableEntity = Assert.IsType<UnprocessableEntityObjectResult>(actionResult);
            // Get the response DTO if it is the expected type
            VerificationResponseDto responseDto = Assert.IsType<VerificationResponseDto>(
                unprocessableEntity.Value);
            // Verify the response DTO message
            Assert.Contains("ensure all details are entered", responseDto.Message);
            // Verify the response DTO status
            Assert.Equal(Status.NotStarted, responseDto.VerificationStatus);
            // Verify logging level was logged
            VerifyLog(LogLevel.Error);
        }

        // Test when the request DTO is valid and passes the service method, 
        // an exception being thrown
        // Should return Ok
        // No need to test other scenarios for the VerificationStatus of the response DTO, 
        // as that is covered in the service tests that includes the logic
        [Fact]
        public async Task VerifyBusiness_ValidDto_ReturnsOk()
        {
            // Arrange
            DomainVerificationController controller = CreateController();
            // Create a request DTO with the test parameters
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto
            {
                UserId = "testuser",
                BusinessEmail = "user@test.com",
                BusinessWebsite = "test.com",
                BusinessName = "testbusiness"
            };
            // Create a response DTO with the test parameters
            VerificationResponseDto controllerResponseDto = new VerificationResponseDto
            {
                VerificationStatus = Status.Accepted,
                Message = "Business successfully verified."
            };
            // Create mock service instance with expected behaviour
            _mockService.Setup(service => service.VerifyBusiness(
                requestDto)).Returns(controllerResponseDto);

            // Act
            var actionResult = await controller.VerifyBusiness(requestDto);

            // Assert
            var ok = Assert.IsType<OkObjectResult>(actionResult);
            VerificationResponseDto responseDto = Assert.IsType<VerificationResponseDto>(ok.Value);
            Assert.Contains("successfully verified", responseDto.Message);
            Assert.Equal(Status.Accepted, responseDto.VerificationStatus);
        }

        // Test when unexpected exception is thrown
        // Should return StatusCode500
        [Fact]
        public async Task VerifyBusiness_ServiceThrowsException_ReturnsStatus500()
        {
            // Arrange
            DomainVerificationController controller = CreateController();
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto
            {
                UserId = "testuser",
                BusinessEmail = "user@test.com",
                BusinessWebsite = "test.com",
                BusinessName = "testbusiness"
            };
            _mockService.Setup(service => service.VerifyBusiness(
                requestDto)).Throws(new System.Exception("Unexpected error."));

            // Act
            var actionResult = await controller.VerifyBusiness(requestDto);

            // Assert
            var statusCode500 = Assert.IsType<ObjectResult>(actionResult);
            // Verify the ObjectResult status code
            Assert.Equal(500, statusCode500.StatusCode);
            VerificationResponseDto responseDto = Assert.IsType<VerificationResponseDto>(statusCode500.Value);
            Assert.Contains("verification failed unexpectedly", responseDto.Message);
            Assert.Equal(Status.NotStarted, responseDto.VerificationStatus);
            VerifyLog(LogLevel.Error);
        }
    }
}
