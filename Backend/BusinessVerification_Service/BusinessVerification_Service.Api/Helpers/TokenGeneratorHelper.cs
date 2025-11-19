using BusinessVerification_Service.Api.Interfaces.HelpersInterfaces;
using System.Security.Cryptography;

namespace BusinessVerification_Service.Api.Helpers
{
    public class TokenGeneratorHelper : ITokenGeneratorHelper
    {
        // Generic method
        //
        // Return a random secure and URL-safe token with a default length
        // of 32 bytes, using cryptography
        public string GenerateToken(int tokenLength = 32)
        {
            // Create byte array
            byte[] tokenBytes = new byte[tokenLength];

            // Populate byte array with random characters
            using (RandomNumberGenerator randomGenerator = RandomNumberGenerator.Create())
            {
                randomGenerator.GetBytes(tokenBytes);
            }

            // Replace and trim string to be URL-safe
            return Convert.ToBase64String(tokenBytes)
                .Replace("+", "-")
                .Replace("/", "_")
                .TrimEnd('=');
        }
    }
}
