using BusinessVerification_Service.Api.Helpers;

namespace BusinessVerification_Service.Test.HelpersTests
{
    [Trait("Category", "TokenGeneratorHelper Unit Testing")]
    public class TokenGeneratorHelperTest
    {
        // Injected dependencies
        private readonly TokenGeneratorHelper _helper;

        // Constructor for dependency injection
        public TokenGeneratorHelperTest()
        {
            _helper = new TokenGeneratorHelper();
        }

        // Test that a token is being generated
        [Fact]
        public void GenerateToken_ShouldGenerateSomething()
        {
            // Arrange and act
            string token = _helper.GenerateToken();

            // Assert
            Assert.False(string.IsNullOrWhiteSpace(token));
        }

        // Test that generated tokes can be of various lenght
        [Theory]
        // Arrange
        [InlineData(16)]
        [InlineData(32)]
        [InlineData(64)]
        public void GenerateToken_ShouldDifferInLength(int tokenLength)
        {
            // Act
            string token = _helper.GenerateToken(tokenLength);

            // Assert
            Assert.InRange(token.Length, 1, 1000);
        }

        // Test that generated tokens are unique
        [Fact]
        public void GenerateToken_ShouldGenerateUniqueResults()
        {
            // Arrange
            List<string> tokens = new List<string>();

            // Act
            for (int i = 0; i < 1000; i++)
            {
                tokens.Add(_helper.GenerateToken());
            }

            // Assert
            int uniqueCount = tokens.Distinct().Count();
            Assert.Equal(tokens.Count, uniqueCount);
        }

        // Test that generated tokens are URL-safe
        [Theory]
        // Arrange
        [InlineData(16)]
        [InlineData(32)]
        [InlineData(64)]
        public void GenerateToken_ShouldGenerateUrlSafeString(int tokenLength)
        {
            // Act
            string token = _helper.GenerateToken(tokenLength);

            // Asserst
            Assert.DoesNotContain("+", token);
            Assert.DoesNotContain("/", token);
            Assert.DoesNotContain("=", token);
        }
    }
}
