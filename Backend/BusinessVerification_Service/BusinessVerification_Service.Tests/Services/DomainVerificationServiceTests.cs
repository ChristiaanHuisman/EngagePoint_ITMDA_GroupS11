using BusinessVerification_Service.Dtos;
using BusinessVerification_Service.Services;
using Microsoft.Extensions.Logging;
using Moq;
using Nager.PublicSuffix;
using Nager.PublicSuffix.RuleProviders;

namespace BusinessVerification_Service.Tests.Services
{
    // Same logic is used for the new DomainVerificationService,
    // that was used in the previous microservice version,
    // thus only limited specific tests are used here
    [Trait("Category", "DomainVerificationService Tests")]
    public class DomainVerificationServiceTests
    {
        private readonly IDomainParser _domainParser;

        public DomainVerificationServiceTests()
        {
            // Use the real public suffix list for testing
            var ruleProvider = new SimpleHttpRuleProvider();
            ruleProvider.BuildAsync().GetAwaiter().GetResult();
            _domainParser = new DomainParser(ruleProvider);
        }

        // Helper method to create the service with a mock logger and the real domain parser
        private DomainVerificationService CreateService(
            out Mock<ILogger<DomainVerificationService>> mockLogger)
        {
            mockLogger = new Mock<ILogger<DomainVerificationService>>();
            return new DomainVerificationService(mockLogger.Object, _domainParser);
        }

        // Test when request DTO is null
        // Should return a rejected status with an error message
        // This test has extensive comments,
        // the following tests will have less comments,
        // as it follows the same structure
        // If following tests need more explanation, 
        // it will be commented accordingly
        [Fact]
        public void VerifyBusiness_NullRequest_ReturnsErrorMessage()
        {
            // Arrange

            // Create a service instance with a mock logger
            var service = CreateService(out var mockLogger);

            // Act

            // Call the method with appropriate test parameters
            var result = service.VerifyBusiness(null);

            // Assert

            // Compare the response message
            Assert.Contains("failed unexpectedly", result.Message, 
                StringComparison.OrdinalIgnoreCase);
            // Compare the response status
            Assert.Equal(Status.Rejected, result.VerificationStatus);
            // Verify that an error was logged
            mockLogger.Verify(logger => logger.Log(
                LogLevel.Error, // Expect a log level of Error 
                It.IsAny<EventId>(), // Do not care about a specific event 
                It.IsAny<It.IsAnyType>(), // Do not care about the state parameter 
                It.IsAny<Exception>(), // Do not care about the exception parameter 
                // Do not care about the formatter function
                (Func<It.IsAnyType, Exception?, string>)It.IsAny<object>()), 
                Times.Once // Ensure logging was called only once
            );
        }
    }
}
