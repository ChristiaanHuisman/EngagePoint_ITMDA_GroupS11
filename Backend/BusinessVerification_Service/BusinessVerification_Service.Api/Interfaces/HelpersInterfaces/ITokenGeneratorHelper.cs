namespace BusinessVerification_Service.Api.Interfaces.HelpersInterfaces
{
    // Include methods from the helper
    public interface ITokenGeneratorHelper
    {
        string GenerateToken(int tokenLength = 32);
    }
}
