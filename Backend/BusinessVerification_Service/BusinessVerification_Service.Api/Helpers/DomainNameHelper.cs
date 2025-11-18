using BusinessVerification_Service.Api.Interfaces.HelpersInterfaces;
using FuzzySharp;

namespace BusinessVerification_Service.Api.Helpers
{
    public class DomainNameHelper : IDomainNameHelper
    {
        // Generic method
        //
        // Return fuzzy match score from 0 to 100
        public int FuzzyMatchScore(string variable1, string variable2)
        {
            // Various algorithms are available, PartialRatio is
            // a good balance and strict enough
            return Fuzz.PartialRatio(variable1, variable2);
        }
    }
}
