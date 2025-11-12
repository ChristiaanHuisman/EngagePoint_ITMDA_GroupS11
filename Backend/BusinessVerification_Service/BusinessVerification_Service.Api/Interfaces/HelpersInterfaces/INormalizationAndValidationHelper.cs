namespace BusinessVerification_Service.Api.Interfaces.HelpersInterfaces
{
    // Include methods from the helper
    public interface INormalizationAndValidationHelper
    {
        string? NormalizeString(string? variable);

        string? RemoveAllWhitespace(string? variable);

        bool IsPopulated(params object?[] items);

        bool IsValidEmailAddress(string emailAddress);
    }
}
