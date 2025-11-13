using Nager.PublicSuffix;
using Nager.PublicSuffix.RuleProviders;

namespace BusinessVerification_Service.Test.Fixtures
{
    // Fixture for one DomainParser instance to be used in all test cases
    public class DomainParserFixture : IDisposable
    {
        // Expose the DomainParser instance to tests
        public IDomainParser DomainParser { get; }

        // To initialize the DomainParser only once for all tests
        public DomainParserFixture()
        {
            // Use the real public suffix list for testing
            SimpleHttpRuleProvider ruleProvider = new();
            ruleProvider.BuildAsync().GetAwaiter().GetResult();
            DomainParser = new DomainParser(ruleProvider);
        }

        // Needed for IDisposable
        public void Dispose() { }
    }
}
