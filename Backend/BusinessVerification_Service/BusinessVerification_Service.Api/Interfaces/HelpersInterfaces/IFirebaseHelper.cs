using FirebaseAdmin.Auth;

namespace BusinessVerification_Service.Api.Interfaces.HelpersInterfaces
{
    // Include methods from the helper
    public interface IFirebaseHelper
    {
        Task<FirebaseToken?> GetDecodedAuthorizationToken(string authorizationToken);

        string? GetUserIdFromToken(FirebaseToken? decodedToken);
    }
}
