using BusinessVerification_Service.Dtos;
using BusinessVerification_Service.Services;
using BusinessVerification_Service.Tests.Fixtures;
using Microsoft.Extensions.Logging;
using Moq;
using Nager.PublicSuffix;

namespace BusinessVerification_Service.Tests.Services
{
    // Same logic is used for the new DomainVerificationService, 
    // that was used in the previous microservice version, 
    // thus only limited specific tests are used here, 
    // as the extensive previous tests all passed
    [Trait("Category", "DomainVerificationService Tests")]
    public class DomainVerificationServiceTests : IClassFixture<DomainParserFixture>
    {
        // Injected dependencies
        private readonly Mock<ILogger<DomainVerificationService>> _mockLogger;
        private readonly IDomainParser _domainParser;

        // Constructor for dependency injection
        public DomainVerificationServiceTests(DomainParserFixture domainParserFixture)
        {
            // Create the mocked logger
            _mockLogger = new Mock<ILogger<DomainVerificationService>>();

            // Get the real domain parser from the fixture
            _domainParser = domainParserFixture.DomainParser;
        }

        // Helper method to create the service
        private DomainVerificationService CreateService()
        {
            return new DomainVerificationService(_mockLogger.Object, _domainParser);
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
        // Test when request DTO is null
        // Should return NotStarted status with an error message
        [Fact]
        public void VerifyBusiness_NullRequest_ReturnsNotStarted()
        {
            // Arrange
            // Create a service instance
            DomainVerificationService service = CreateService();

            // Act
            // Call the method with appropriate test parameters
            VerificationResponseDto responseDto = service.VerifyBusiness(null);

            // Assert
            // Verify the response DTO message
            Assert.Contains("failed unexpectedly", responseDto.Message, 
                StringComparison.OrdinalIgnoreCase);
            // Verify the response DTO status
            Assert.Equal(Status.NotStarted, responseDto.VerificationStatus);
            // Verify logging level was logged
            VerifyLog(LogLevel.Error);
        }

        // Test when required fields are empty
        // Should return NotStarted status with an error message
        [Fact]
        public void VerifyBusiness_EmptyFieldsRequest_ReturnsNotStarted()
        {
            // Arrange
            DomainVerificationService service = CreateService();
            // Create a request DTO with the test parameters
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = "user@test.com", 
                BusinessWebsite = "test.com", 
                BusinessName = " "
            };

            // Act
            VerificationResponseDto responseDto = service.VerifyBusiness(requestDto);

            // Assert
            Assert.Contains("ensure all details", responseDto.Message);
            Assert.Equal(Status.NotStarted, responseDto.VerificationStatus);
            VerifyLog(LogLevel.Warning);
        }

        // Test when email format is invalid
        // Should return NotStarted status with an error message
        [Fact]
        public void VerifyBusiness_InvalidEmailFormat_ReturnsNotStarted()
        {
            // Arrange
            DomainVerificationService service = CreateService();
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = "usertest.com", 
                BusinessWebsite = "test.com", 
                BusinessName = "testbusiness"
            };

            // Act
            VerificationResponseDto responseDto = service.VerifyBusiness(requestDto);

            // Assert
            Assert.Contains("incomplete email format", responseDto.Message);
            Assert.Equal(Status.NotStarted, responseDto.VerificationStatus);
            VerifyLog(LogLevel.Warning);
        }

        // Test when website format is invalid
        // Should return NotStarted status with an error message
        [Theory]
        [InlineData("invalid")]
        public void VerifyBusiness_InvalidWebsiteFormat_ReturnsNotStarted(
            string website)
        {
            // Arrange
            DomainVerificationService service = CreateService();
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = "user@test.com", 
                BusinessWebsite = website, 
                BusinessName = "testbusiness"
            };

            // Act
            VerificationResponseDto responseDto = service.VerifyBusiness(requestDto);

            // Assert
            Assert.Contains("incomplete email or website format", responseDto.Message);
            Assert.Equal(Status.NotStarted, responseDto.VerificationStatus);
            VerifyLog(LogLevel.Warning);
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
            DomainVerificationService service = CreateService();
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = "user@test.com", 
                BusinessWebsite = website, 
                BusinessName = "testbusiness"
            };

            // Act
            VerificationResponseDto responseDto = service.VerifyBusiness(requestDto);

            // Assert
            Assert.Contains("incomplete website format", responseDto.Message);
            Assert.Equal(Status.NotStarted, responseDto.VerificationStatus);
            VerifyLog(LogLevel.Warning);
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
            DomainVerificationService service = CreateService();
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = email, 
                BusinessWebsite = website, 
                BusinessName = "testbusiness"
            };

            // Act
            VerificationResponseDto responseDto = service.VerifyBusiness(requestDto);

            // Assert
            Assert.Contains("domains entered do not match", responseDto.Message);
            Assert.Equal(Status.Rejected, responseDto.VerificationStatus);
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
            DomainVerificationService service = CreateService();
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = email, 
                BusinessWebsite = website, 
                BusinessName = name
            };

            // Act
            VerificationResponseDto responseDto = service.VerifyBusiness(requestDto);

            // Assert
            Assert.Contains("successfully verified", responseDto.Message);
            Assert.Equal(Status.Accepted, responseDto.VerificationStatus);
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
            DomainVerificationService service = CreateService();
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = email, 
                BusinessWebsite = website, 
                BusinessName = name
            };

            // Act
            VerificationResponseDto responseDto = service.VerifyBusiness(requestDto);

            // Assert
            Assert.Contains("review required", responseDto.Message);
            Assert.Equal(Status.Pending, responseDto.VerificationStatus);
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
            DomainVerificationService service = CreateService();
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = email, 
                BusinessWebsite = website, 
                BusinessName = name
            };

            // Act
            VerificationResponseDto responseDto = service.VerifyBusiness(requestDto);

            // Assert
            Assert.Contains("does not match", responseDto.Message);
            Assert.Equal(Status.Rejected, responseDto.VerificationStatus);
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
            mockParser.Setup(parser => parser.Parse(It.IsAny<string>()))
                .Throws(new Exception("unexpected error"));
            DomainVerificationService service = new DomainVerificationService(
                _mockLogger.Object, mockParser.Object);
            DomainVerificationRequestDto requestDto = new DomainVerificationRequestDto
            {
                UserId = "testuser", 
                BusinessEmail = "user@test.com", 
                BusinessWebsite = "test.com", 
                BusinessName = "testbusiness"
            };

            // Act
            VerificationResponseDto responseDto = service.VerifyBusiness(requestDto);

            // Assert
            Assert.Contains("failed unexpectedly", responseDto.Message);
            Assert.Equal(Status.NotStarted, responseDto.VerificationStatus);
            VerifyLog(LogLevel.Error);
        }
    }
}
