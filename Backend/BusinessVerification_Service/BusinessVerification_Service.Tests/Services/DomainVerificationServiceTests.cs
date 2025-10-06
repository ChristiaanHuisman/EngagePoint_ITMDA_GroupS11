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

        // Test various cases of email and website combinations
        [Theory]
        [InlineData("person@example.com", "https://www.example.com", true)] // Matching - valid
        [InlineData("person@example.com", "https://example.com", true)] // Matching no www - valid
        [InlineData("person@example.com", "www.example.com", true)] // Matching no https - valid
        [InlineData("person@example.com", "example.com", true)] // Matching no www and no https - valid
        [InlineData("person@example.com", "http://www.example.com", true)] // Matching http - valid
        [InlineData("person@role.example.com", "https://www.role.example.com", true)] // Matching subdomain - valid
        [InlineData("person@role.example.com", "https://www.example.com", true)] // Matching missing subdomain - valid
        [InlineData("person@role.example.com", "https://www.different.example.com", true)] // Non-matching subdomain - valid
        [InlineData("person@example.com", "https://www.example.com/tab", true)] // Matching with path - valid
        [InlineData("person@example.com", "https://www.example.com/tab/specific", true)] // Matching with extended path - valid
        [InlineData("person@example.com", "https://www.different.com/tab", false)] // Non-matching with path - invalid
        [InlineData("person@role.example.com", "http://different.example.com/tab/specific", true)] // Extreme example - valid
        [InlineData("person@role.example.com", "http://different.example.co.za/tab/specific", false)] // Extreme example - invalid
        [InlineData("person@role.example.com", "http://differnet.com/tab/specific", false)] // Extreme example - invalid
        [InlineData("person@example.com", "https://www.different.com", false)] // Non-matching - invalid
        [InlineData("person@example.com", "https://www.example.co.za", false)] // Non-matching suffix - invalid
        [InlineData("person@example.com", "https://www.different.co.za", false)] // Non-matching and non-matching suffix - invalid
        [InlineData("person@example.qld.gov.au", "https://www.example.qld.gov.au", true)] // Matching long suffix - valid
        [InlineData("person@example.qld.gov.au", "https://www.different.qld.gov.au", false)] // Non-matching long suffix - invalid
        [InlineData("person@example.個人.hk", "https://www.example.個人.hk", true)] // Mathcing weird suffix - valid
        [InlineData("person@example.個人.hk", "https://www.different.個人.hk", false)] // Non-mathcing weird suffix - invalid
        [InlineData("person@example.個人.hk", "https://www.example.公司.hk", false)] // Non-matching and weird suffix - invalid
        [InlineData("person@example.xyz123", "https://www.example.xyz123", false)] // Matching non-existent suffix - invalid
        [InlineData("person@example.xyz123", "https://www.different.xyz123", false)] // Non-matching and non-existent suffix - invalid
        [InlineData("person@example.xyz123", "https://www.example.xyz1234", false)] // Non-matching non-existent suffix - invalid
        [InlineData("person@example", "https://www.example", false)] // Matching no suffix - invalid
        [InlineData("person@example", "https://www.different", false)] // Non-matching no suffix - invalid
        [InlineData("person@example.com", "https://www.example", false)] // Matching missing suffix - invalid
        [InlineData("person@.com", "https://www..com", false)] // No domain - invalid
        [InlineData("person@.com", "https://www..co.za", false)] // No domain non-matching suffix - invalid
        [InlineData("person@com", "https://www.com", false)] // No domain missing . suffix - invalid
        [InlineData("person@com", "https://www.co.za", false)] // No domain non-matching and missing . suffix - invalid
        [InlineData("person@.com", "https://.com", false)] // No domain no www - invalid
        [InlineData("person@com", "https://com", false)] // No domain missing . suffix no www - invalid
        [InlineData("PERSON@EXAMPLE.COM", "https://www.example.com", true)] // Uppercase email - valid
        [InlineData("person@example.com", "HTTPS://www.EXAMPLE.COM", true)] // Uppercase website - valid
        [InlineData("PERSON@EXAMPLE.COM", "HTTPS://www.EXAMPLE.COM", true)] // Uppercase - valid
        [InlineData("person@example.com ", " https://www.example.com", true)] // Leading and trailing spaces - valid
        [InlineData("person@example.com", "https://www.example.com/", true)] // Trailing / - valid
        [InlineData("person@example.tech", "https://www.example.tech", true)] // Modern TLD - valid
        [InlineData("person@person-example.com", "https://www.person-example.com", true)] // Hyphenated domain - valid
        [InlineData("person@example123.com", "https://www.example123.com", true)] // Numeric domain - valid
        [InlineData("person@specific.role.example.com", "https://www.example.com", true)] // Multi subdomain - valid
        [InlineData("person@specific.role.example.com", "https://www.role.example.com", true)] // Multi subdomain - valid
        [InlineData("person@specific.role.example.com", "https://www.specific.role.example.com", true)] // Multi subdomain - valid
        [InlineData("person@sub.sub.sub.sub.sub.example.com", "https://example.com", true)] // Deep subdomain - valid
        [InlineData("personexample.com", "example.com", false)] // Missing @ - invalid
        [InlineData("person@example.com", "https://www.192.168.1.1", false)] // IP - invalid
        [InlineData("person+alias@example.com", "https://www.example.com", true)] // Email alias - valid
        [InlineData("person@example.com", "https://www.example.com:8080", true)] // Port number - valid
        [InlineData("person@example.com", "ftp://example.com", true)] // Mixed protocal - valid
        [InlineData("person@xn--fsq.com", "https://xn--fsq.com", true)] // Punycode domain - valid
        [InlineData("person@example.com.", "https://www.example.com.", false)] // Trailing . - invalid
        [InlineData("person@example.", "https://www.example.", false)] // No suffix trailing . - invalid
        [InlineData("person@example.com", "tps://www.example.com", false)] // Wrong start of website - invalid
        [InlineData("person@example.com", "://www.example.com", false)] // Wrong start of website - invalid
        [InlineData("person@example.com", "/www.example.com", false)] // Wrong start of website - invalid
        [InlineData("person@example.com", "/example.com", false)] // Wrong start of website without www - invalid
        public void VerifyDomainMatch_VariousCases_ReturnsExpected(
            string email, string website, bool expectedResult)
        {
            // Arrange
            var service = CreateService();

            // Act
            bool result = service.VerifyDomainMatch(email, website);

            // Assert
            Assert.Equal(expectedResult, result);
        }

        // Test invalid email or website throws ArgumentException
        [Theory]

        public void VerifyDomainMatch_InvalidInputs_ThrowsArgumentException(
            string email, string website)
        {
            // Arrange
            var service = CreateService();

            // Act and assert
            Assert.Throws<ArgumentException>(() 
                => service.VerifyDomainMatch(email, website)
            );
        }

        // Test empty email or website throws ArgumentNullException
        [Theory]
        [InlineData("", "example.com")]
        [InlineData("user@example.com", "")]
        [InlineData(" ", "example.com")]
        [InlineData("user@example.com", " ")]
        [InlineData("", "")]
        [InlineData(" ", " ")]
        public void VerifyDomainMatch_EmptyEmailOrWebsite_ThrowsArgumentNullException(
            string email, string website)
        {
            // Arrange
            var service = CreateService();

            // Act and assert
            Assert.Throws<ArgumentNullException>(() 
                => service.VerifyDomainMatch(email, website)
            );
        }
    }
}
