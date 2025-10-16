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

        // This test has extensive comments,
        // the following tests will have less comments,
        // as it follows the same structure
        // If following tests need more explanation, 
        // it will be commented accordingly
        // Test when request DTO is null
        // Should return NotStarted status with an error message
        [Fact]
        public void VerifyBusiness_NullRequest_ReturnsNotStarted()
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
            Assert.Equal(Status.NotStarted, result.VerificationStatus);
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

        // Test when required fields are empty
        // Should return NotStarted status with an error message
        [Fact]
        public void VerifyBusiness_EmptyFieldsRequest_ReturnsNotStarted()
        {
            // Arrange
            var service = CreateService(out var mockLogger);
            // Create a request DTO with the test parameters
            var dto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = "user@test.com", 
                BusinessWebsite = "test.com", 
                BusinessName = " "
            };

            // Act
            var result = service.VerifyBusiness(dto);

            // Assert
            Assert.Contains("ensure all details", result.Message);
            Assert.Equal(Status.NotStarted, result.VerificationStatus);
            mockLogger.Verify(logger => logger.Log(
                LogLevel.Warning, 
                It.IsAny<EventId>(), 
                It.IsAny<It.IsAnyType>(), 
                It.IsAny<Exception>(), 
                (Func<It.IsAnyType, Exception?, string>)It.IsAny<object>()), 
                Times.AtLeastOnce
            );
        }

        // Test when email format is invalid
        // Should return NotStarted status with an error message
        [Fact]
        public void VerifyBusiness_InvalidEmailFormat_ReturnsNotStarted()
        {
            // Arrange
            var service = CreateService(out var mockLogger);
            var dto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = "usertest.com", 
                BusinessWebsite = "test.com", 
                BusinessName = "testbusiness"
            };

            // Act
            var result = service.VerifyBusiness(dto);

            // Assert
            Assert.Contains("incomplete email format", result.Message);
            Assert.Equal(Status.NotStarted, result.VerificationStatus);
            mockLogger.Verify(logger => logger.Log(
                LogLevel.Warning, 
                It.IsAny<EventId>(), 
                It.IsAny<It.IsAnyType>(), 
                It.IsAny<Exception>(), 
                (Func<It.IsAnyType, Exception?, string>)It.IsAny<object>()), 
                Times.AtLeastOnce
            );
        }

        // Test when website format is invalid
        // Should return NotStarted status with an error message
        [Theory]
        [InlineData("invalid")]
        public void VerifyBusiness_InvalidWebsiteFormat_ReturnsNotStarted(
            string website)
        {
            // Arrange
            var service = CreateService(out var mockLogger);
            var dto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = "user@test.com", 
                BusinessWebsite = website, 
                BusinessName = "testbusiness"
            };

            // Act
            var result = service.VerifyBusiness(dto);

            // Assert
            Assert.Contains("incomplete email or website format", result.Message);
            Assert.Equal(Status.NotStarted, result.VerificationStatus);
            mockLogger.Verify(logger => logger.Log(
                LogLevel.Warning, 
                It.IsAny<EventId>(), 
                It.IsAny<It.IsAnyType>(), 
                It.IsAny<Exception>(), 
                (Func<It.IsAnyType, Exception?, string>)It.IsAny<object>()), 
                Times.AtLeastOnce
            );
        }

        // Test when website format or scheme is invalid for UriBuilder
        // Should return NotStarted status with an error message
        [Theory]
        [InlineData("https://<completely invalid>.com")]
        [InlineData("https://tps://test.com")]
        [InlineData("tps://test.com")]
        [InlineData("://test.com")]
        [InlineData(":/test.com")]
        [InlineData(":test.com")]
        [InlineData("/test.com")]
        public void VerifyBusiness_InvalidWebsiteShemeOrUriFormat_ReturnsNotStarted(
            string website)
        {
            // Arrange
            var service = CreateService(out var mockLogger);
            var dto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = "user@test.com", 
                BusinessWebsite = website, 
                BusinessName = "testbusiness"
            };

            // Act
            var result = service.VerifyBusiness(dto);

            // Assert
            Assert.Contains("incomplete website format", result.Message);
            Assert.Equal(Status.NotStarted, result.VerificationStatus);
            mockLogger.Verify(logger => logger.Log(
                LogLevel.Warning, 
                It.IsAny<EventId>(), 
                It.IsAny<It.IsAnyType>(), 
                It.IsAny<Exception>(), 
                (Func<It.IsAnyType, Exception?, string>)It.IsAny<object>()), 
                Times.AtLeastOnce
            );
        }

        // Test when email and website domains do not match
        // Should return Rejected status with a rejected message
        [Theory]
        [InlineData("user@test.com", "different.com")]
        [InlineData("   user@test.com", "test.co.za")]
        [InlineData("user@test.com", "test.com.co.za")]
        public void VerifyBusiness_EmailAndWebsiteDoNotMatch_ReturnsRejected(
            string email, string website)
        {
            // Arrange
            var service = CreateService(out var mockLogger);
            var dto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = email, 
                BusinessWebsite = website, 
                BusinessName = "testbusiness"
            };

            // Act
            var result = service.VerifyBusiness(dto);

            // Assert
            Assert.Contains("domains entered do not match", result.Message);
            Assert.Equal(Status.Rejected, result.VerificationStatus);
        }

        // Test when all details are valid and business name completely match
        // Fuzzy match score >= 90
        // Should return Accepted status with an accepted message
        [Theory]
        [InlineData("user@test.com", "ftp://test.com", "test")]
        [InlineData("user+alias@test.com", "test.com/path", "test     ")]
        [InlineData("info@microsoft.com", "microsoft.com", "MicroSoft Solutions")]
        [InlineData("info@google.co.za", "store.google.co.za", " Google South Africa")]
        [InlineData("contact@apple.com", "apple.com", "Apple Corp")]
        [InlineData("support@amazon.com", "amazon.com", "Amazon Online Store")]
        public void VerifyBusiness_HighFuzzyScore_ReturnsAccepted(
            string email, string website, string name)
        {
            // Arrange
            var service = CreateService(out var mockLogger);
            var dto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = email, 
                BusinessWebsite = website, 
                BusinessName = name
            };

            // Act
            var result = service.VerifyBusiness(dto);

            // Assert
            Assert.Equal(Status.Accepted, result.VerificationStatus);
            Assert.Contains("successfully verified", result.Message, StringComparison.OrdinalIgnoreCase);
        }

        // Test when all details are valid and business name partially match
        // Fuzzy match score >= 65 and <= 89
        // Should return Pending status with a pending message
        [Theory]
        [InlineData("admin@google.com", "google.com", "Googl Services")]
        [InlineData("contact@apple.com", "apple.com", "Appl Inc")]
        [InlineData("sales@amazon.com", "amazon.com/profile/settings", "Amazn Online")]
        [InlineData("contact@google.com", "google.com", "Gogle Online Services")]
        [InlineData("support@apple.com", "apple.com", "Aple Computers")]
        [InlineData("admin@amazon.com", "amazon.com", "Amazoon Online")]
        [InlineData("support@apple.com", "apple.com", "Appl Inc Corp")]
        public void VerifyBusiness_MediumFuzzyScore_ReturnsPending(
            string email, string website, string name)
        {
            // Arrange
            var service = CreateService(out var mockLogger);
            var dto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = email, 
                BusinessWebsite = website, 
                BusinessName = name
            };

            // Act
            var result = service.VerifyBusiness(dto);

            // Assert
            Assert.Equal(Status.Pending, result.VerificationStatus);
            Assert.Contains("review required", result.Message, StringComparison.OrdinalIgnoreCase);
        }

        // Test when all details are valid and business name does not match
        // Fuzzy match score <= 64
        // Should return Rejected status with a rejected message
        [Theory]
        [InlineData("user@test.com", "test.com", "differentbusiness")]
        [InlineData("info@microsoft.com", "microsoft.com", "Expert Solutions")]
        [InlineData("admin@google.com", "google.com", "Tech South Africa")]
        [InlineData("contact@apple.com", "applecare.apple.com", "Fruit Corp")]
        [InlineData("sales@amazon.com", "books.amazon.com", "Ecommerce World")]
        [InlineData("info@microsoft.com", "microsoft.com", "Micro Tech Co.")]
        [InlineData("contact@google.com", "google.com", "Ggl Services Ltd")]
        [InlineData("admin@amazon.com", "amazon.com", "Amzn E-Commerce")]
        public void VerifyBusiness_LowFuzzyScore_ReturnsRejected(
            string email, string website, string name)
        {
            // Arrange
            var service = CreateService(out var mockLogger);
            var dto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = email, 
                BusinessWebsite = website, 
                BusinessName = name
            };

            // Act
            var result = service.VerifyBusiness(dto);

            // Assert
            Assert.Equal(Status.Rejected, result.VerificationStatus);
            Assert.Contains("does not match", result.Message, StringComparison.OrdinalIgnoreCase);
        }

        // Test when unexpected exception is thrown
        // Should return NotStarted status with an error message
        [Fact]
        public void VerifyBusiness_ThrowsUnexpectedException_ReturnsNotStarted()
        {
            // Arrange
            // Mock the domain parser to throw an exception
            var mockParser = new Mock<IDomainParser>();
            // Setup the behaviour of the mock parser
            mockParser.Setup(parser => parser.Parse(It.IsAny<string>())).Throws(new Exception(
                "unexpected error"));
            var mockLogger = new Mock<ILogger<DomainVerificationService>>();
            var service = new DomainVerificationService(mockLogger.Object, mockParser.Object);
            var dto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = "user@test.com", 
                BusinessWebsite = "test.com", 
                BusinessName = "testbusiness"
            };

            // Act
            var result = service.VerifyBusiness(dto);

            // Assert
            Assert.Contains("failed unexpectedly", result.Message, StringComparison.OrdinalIgnoreCase);
            Assert.Equal(Status.NotStarted, result.VerificationStatus);
            mockLogger.Verify(logger => logger.Log(
                LogLevel.Error, 
                It.IsAny<EventId>(), 
                It.IsAny<It.IsAnyType>(), 
                It.IsAny<Exception>(), 
                (Func<It.IsAnyType, Exception?, string>)It.IsAny<object>()), 
                Times.Once
            );
        }
    }
}
