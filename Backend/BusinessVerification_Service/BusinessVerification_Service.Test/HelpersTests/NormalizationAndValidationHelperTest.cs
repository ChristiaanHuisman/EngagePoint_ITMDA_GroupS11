using BusinessVerification_Service.Api.Helpers;

namespace BusinessVerification_Service.Test.HelpersTests
{
    [Trait("Category", "NormalizationAndValidationHelper Unit Testing")]
    public class NormalizationAndValidationHelperTest
    {
        // Injected dependencies
        private readonly NormalizationAndValidationHelper _helper;

        // Constructor for dependency injection
        public NormalizationAndValidationHelperTest()
        {
            _helper = new NormalizationAndValidationHelper();
        }

        // Test string normalization
        [Fact]
        public void NormalizeString_ShouldNormalize()
        {
            // Arrange
            string? input = "   Héllo,  Wörld!!  ";

            // Act
            string? result = _helper.NormalizeString(input);

            // Assert
            Assert.Equal("hello, world", result);
        }

        // Test string normalization when input is null
        [Fact]
        public void NormalizeString_ShouldReturnNull()
        {
            // Arrange
            string? input = null;

            // Act
            string? result = _helper.NormalizeString(input);

            // Assert
            Assert.Null(result);
        }

        // Test removing all spaces, tabs and new lines
        [Fact]
        public void RemoveAllWhitespace_ShouldRemoveAllSpacesTabsAndNewlines()
        {
            // Arrange
            string? input = "  a    b\tc\nd ";

            // Act
            string? result = _helper.RemoveAllWhitespace(input);

            // Assert
            Assert.Equal("abcd", result);
        }

        // Test removing all spaces when input is null
        [Fact]
        public void RemoveAllWhitespace_ShouldReturnNull()
        {
            // Arrange
            string? input = null;

            // Act
            string? result = _helper.RemoveAllWhitespace(input);

            // Assert
            Assert.Null(result);
        }

        // Test population when everything has values
        [Fact]
        public void IsPopulated_ShouldReturnTrue()
        {
            // Arrange
            string? inputString = "test";
            int? inputInt = 1;

            // Act
            bool result = _helper.IsPopulated(inputString, inputInt);

            // Assert
            Assert.True(result);
        }

        // Test population when something is null or empty
        [Theory]
        // Arrange
        [InlineData("test", null)]
        [InlineData("   ", 1)]
        public void IsPopulated_ShouldReturnFalse(
            string? inputString, int? inputInt)
        {
            // Act
            bool result = _helper.IsPopulated(inputString, inputInt);

            // Assert
            Assert.False(result);
        }

        // Test email format when email address is in valid format
        [Fact]
        public void IsValidEmailAddress_ShouldReturnTrue()
        {
            // Arrange
            string input = "test@email.com";

            // Act
            bool result = _helper.IsValidEmailAddress(input);

            // Assert
            Assert.True(result);
        }

        // Test email format when email address is not in valid format
        [Fact]
        public void IsValidEmailAddress_ShouldReturnFalse()
        {
            // Arrange
            string input = "invalid-test@";

            // Act
            bool result = _helper.IsValidEmailAddress(input);

            // Assert
            Assert.False(result);
        }
    }
}
