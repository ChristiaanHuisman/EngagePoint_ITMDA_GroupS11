using BusinessVerification_Service.Interfaces;
using BusinessVerification_Service.Services;
using Microsoft.Extensions.Logging.Abstractions;
using Nager.PublicSuffix;
using Nager.PublicSuffix.RuleProviders;

namespace BusinessVerification_Service.Tests.Services
{
    // Most possible test cases for email and website combinations entered by users
    // including valid matches, invalid matches, and various edge cases
    // for the DomainVerificationService.VerifyDomainMatch method is covered here
    [Trait("Category", "Service Tests")]
    public class DomainVerificationServiceTests
    {
        // Helper method to create a service instance with real dependencies
        private IDomainVerificationService CreateService()
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
        [InlineData("person+alias@example.com", "https://www.example.com", true)] // Email alias - valid
        [InlineData("person@example.com", "https://www.example.com:8080", true)] // Port number - valid
        [InlineData("person@example.com", "ftp://example.com", true)] // Mixed protocal - valid
        [InlineData("person@xn--fsq.com", "https://xn--fsq.com", true)] // Punycode domain - valid
        [InlineData("person@com.com", "https://www.com.com", true)] // Matching registerable and top-level domain - valid
        public void VerifyDomainMatch_VariousCases_ReturnsExpected(
            string email, string website, bool expectedResult)
        {
            // Arrange
            IDomainVerificationService service = CreateService();

            // Act
            bool result = service.VerifyDomainMatch(email, website);

            // Assert
            Assert.Equal(expectedResult, result);
        }

        // Test invalid email or website throws ArgumentException
        [Theory]
        [InlineData("person@.com", "https://www..com")] // No domain
        [InlineData("person@.com", "https://www..co.za")] // No domain non-matching suffix
        [InlineData("person@.com", "https://.com")] // No domain no www
        [InlineData("personexample.com", "example.com")] // Missing @
        [InlineData("@", "https://www.example.com")] // Weird case
        [InlineData("<person@example.com", "https://www.example.com")] // Email starting with <
        [InlineData(".person@example.com", "https://www.example.com")] // Email starting with .
        [InlineData("person@example.com>", "https://www.example.com>")] // Trailing >
        [InlineData("person@example.xyz123", "https://www.example.xyz123")] // Matching non-existent suffix
        [InlineData("person@example.xyz123", "https://www.different.xyz123")] // Non-matching and non-existent suffix
        [InlineData("person@example.xyz123", "https://www.example.xyz1234")] // Non-matching non-existent suffix
        [InlineData("person@example.com", "https://www.192.168.1.1")] // IP
        [InlineData("person@example.com", "tps://www.example.com")] // Wrong start of website
        [InlineData("person@example", "https://www.example")] // Matching no suffix
        [InlineData("person@example", "https://www.different")] // Non-matching no suffix
        [InlineData("person@example.com", "https://www.example")] // Matching missing suffix
        [InlineData("person@example.", "https://www.example.")] // No suffix trailing .
        [InlineData("person@example.com.", "https://www.example.com.")] // Trailing .
        [InlineData("person@example.com", ".")] // Weird case
        [InlineData("person@com", "https://www.com")] // No domain missing . suffix
        [InlineData("person@com", "https://www.co.za")] // No domain non-matching and missing . suffix
        [InlineData("person@com", "https://com")] // No domain missing . suffix no www
        [InlineData("person@example.com", "/example.com")] // Wrong start of website without www
        [InlineData("person@example.com", "/www.example.com")] // Wrong start of web
        [InlineData("person@example.com", "https://www.example.com>")] // Weird case
        [InlineData("person@example.com", "://www.example.com")] // Wrong start of website
        [InlineData("person@example.com", "<https://www.example.com")] // Website starting with <
        [InlineData("person@example.com", ".https://www.example.com")] // Website starting with .
        // Test empty email or website
        [InlineData("", "example.com")]
        [InlineData("user@example.com", "")]
        [InlineData(" ", "example.com")]
        [InlineData("user@example.com", " ")]
        [InlineData("", "")]
        [InlineData(" ", " ")]
        [InlineData("     ", "     ")]
        [InlineData(null, "example.com")]
        [InlineData("user@example.com", null)]
        [InlineData(null, null)]
        public void VerifyDomainMatch_InvalidInputs_ThrowsArgumentException(
            string email, string website)
        {
            // Arrange
            IDomainVerificationService service = CreateService();

            // Act and assert
            Assert.Throws<ArgumentException>(() 
                => service.VerifyDomainMatch(email, website)
            );
        }
    }
}
