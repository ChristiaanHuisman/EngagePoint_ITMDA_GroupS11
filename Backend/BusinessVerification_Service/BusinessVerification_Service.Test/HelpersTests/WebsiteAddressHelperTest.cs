using BusinessVerification_Service.Api.Helpers;

namespace BusinessVerification_Service.Test.HelpersTests
{
    [Trait("Category", "WebsiteAddressHelper Unit Testing")]
    public class WebsiteAddressHelperTest
    {
        // Injected dependencies
        private readonly WebsiteAddressHelper _helper;

        // Constructor for dependency injection
        public WebsiteAddressHelperTest()
        {
            _helper = new WebsiteAddressHelper();
        }

        // Test different valid website schemes
        [Theory]
        // Arrange
        [InlineData("https://test.com")]
        [InlineData("http://test.com")]
        [InlineData("ftp://test.com")]
        [InlineData("test.com")]
        [InlineData("test")]
        public void VerifyWebsiteAddressScheme_ShouldReturnTrue(string input)
        {
            // Act
            bool result = _helper.VerifyWebsiteAddressScheme(input);

            // Assert
            Assert.True(result);
        }

        // Test different invalid website schemes
        [Theory]
        // Arrange
        [InlineData("invalid://test.com")]
        [InlineData("https://https://test.com")]
        public void VerifyWebsiteAddressScheme_ShouldReturnFalse(string input)
        {
            // Act
            bool result = _helper.VerifyWebsiteAddressScheme(input);

            // Assert
            Assert.False(result);
        }

        // Test URI helper to add correct shcemes
        [Theory]
        // Arrange
        [InlineData("test.com", "https://test.com/")]
        [InlineData("http://test.com", "http://test.com/")]
        [InlineData("ftp://test.com", "ftp://test.com/")]
        [InlineData("www.test.com/path", "https://www.test.com/path")]
        [InlineData("test", "https://test/")]
        public void BuildUriWebsiteAddress_ShouldHandleInputs(string input, string expected)
        {
            // Act
            string result = _helper.BuildUriWebsiteAddress(input);

            // Assert
            Assert.Equal(expected, result);
        }
    }
}
