namespace BusinessVerification_Service.Api.Interfaces.HelpersInterfaces
{
    // Include methods from the helper
    public interface IDomainNameHelper
    {
        int FuzzyMatchScore(string variable1, string variable2);
    }
}
