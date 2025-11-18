using BusinessVerification_Service.Api.Interfaces.HelpersInterfaces;
using System.Globalization;
using System.Net.Mail;
using System.Text;
using System.Text.RegularExpressions;

namespace BusinessVerification_Service.Api.Helpers
{
    public class NormalizationAndValidationHelper : INormalizationAndValidationHelper
    {
        // Return normalized string
        public string? NormalizeString(string? variable)
        {
            if (variable == null)
            {
                return null;
            }

            variable = variable.Trim().ToLower();

            // Collapse extra spaces
            variable = Regex.Replace(variable, @"\s+", " ");

            // Remove punctuation at ends
            variable = variable.Trim().Trim('.', ',', ';', ':', '!', '?', '/', '\\', '@');

            // Remove diacritics (accents)
            var normalizedVariable = variable.Normalize(NormalizationForm.FormD);
            var stringBuilder = new StringBuilder();
            foreach (char character in normalizedVariable)
            {
                if (CharUnicodeInfo.GetUnicodeCategory(character)
                    != UnicodeCategory.NonSpacingMark)
                {
                    stringBuilder.Append(character);
                }
            }

            // Recombine string
            return stringBuilder.ToString().Normalize(NormalizationForm.FormC);

        }

        // Return string with all whitespace removed
        public string? RemoveAllWhitespace(string? variable)
        {
            if (variable == null)
            {
                return null;
            }

            // Remove all whitespace
            return Regex.Replace(variable, @"\s+", "");
        }

        // Generic method
        //
        // Return true if all passed types are populated
        public bool IsPopulated(params object?[] items)
        {
            foreach (var item in items)
            {
                // Check if null
                if (item == null)
                {
                    return false;
                }

                // Check different passed types
                switch (item)
                {
                    case string stringCheck:
                        if (string.IsNullOrWhiteSpace(stringCheck))
                        {
                            return false;
                        }
                    break;
                    default:
                        // Other types are only checked for null
                    break;
                }
            }

            return true;
        }

        // Return true if string is a valid email address
        public bool IsValidEmailAddress(string emailAddress)
        {
            try
            {
                MailAddress mailAddress = new MailAddress(emailAddress);
                return mailAddress.Address == emailAddress;
            }
            catch
            {
                // For in case parsing goes wrong
                return false;
            }
        }
    }
}
