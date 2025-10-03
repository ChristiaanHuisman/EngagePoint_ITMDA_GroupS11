using BusinessVerification_Service.Services;
using Microsoft.Extensions.Logging.Abstractions;
using Nager.PublicSuffix;
using Nager.PublicSuffix.RuleProviders;

namespace BusinessVerification_Service.Tests.Services
{
    public class DomainVerificationServiceTests
    {
        private DomainVerificationService CreateService()
        {
            // Use NullLogger for testing purposes that won't log anything
            var logger = NullLogger<DomainVerificationService>.Instance;

            // Use the real domain parser to download the newest public suffix list
            var ruleProvider = new SimpleHttpRuleProvider();
            ruleProvider.BuildAsync().GetAwaiter().GetResult();
            var domainParser = new DomainParser(ruleProvider);

            // Return the service
            return new DomainVerificationService(logger, domainParser);
        }

        [Fact]
        public void VerifyDomainMatch_ValidMatch_ReturnsTrue()
        {
            // Arrange
            var service = CreateService();
            string email = "person@admin.example.co.za";
            string website = "example.co.za/tab";

            // Act
            bool result = service.VerifyDomainMatch(email, website);

            // Assert
            Assert.True(result);
        }

        [Fact]
        public void VerifyDomainMatch_ValidNoMatch_ReturnsFalse()
        {
            // Arrange
            var service = CreateService();
            string email = "person@example.com";
            string website = "https://differntexample.com";

            // Act
            bool result = service.VerifyDomainMatch(email, website);

            // Assert
            Assert.False(result);
        }
    }
}
