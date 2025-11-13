using BusinessVerification_Service.Api.Interfaces.HelpersInterfaces;
using FirebaseAdmin.Auth;

namespace BusinessVerification_Service.Api.Helpers
{
    public class FirebaseHelper : IFirebaseHelper
    {
        // Return the decoded token
        public async Task<FirebaseToken?> GetDecodedAuthorizationToken(string authorizationToken)
        {
            try
            {
                // Validate the token signature, issuer and expiry
                // using Firebase public keys
                FirebaseToken decodedToken = await
                    FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(
                    authorizationToken);

                // If the decoding succeeds, the token is valid
                return decodedToken;
            }
            catch
            {
                // If the token is not valid
                return null;
            }
        }

        // Return the related user UID of the validated token
        public string? GetUserIdFromToken(FirebaseToken? decodedToken)
        {
            try
            {
                // Get the user UID from the decoded token
                return decodedToken?.Uid;
            }
            catch
            {
                // If the user UID cannot be returned
                return null;
            }
        }
    }
}
