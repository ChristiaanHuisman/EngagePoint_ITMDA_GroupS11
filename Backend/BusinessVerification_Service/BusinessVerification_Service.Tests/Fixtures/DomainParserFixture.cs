using Nager.PublicSuffix;
using Nager.PublicSuffix.RuleProviders;

namespace BusinessVerification_Service.Tests.Fixtures
{
    public class DomainParserFixture : IDisposable
    {
        // Expose the DomainParser instance to tests
        public IDomainParser DomainParser { get; }

        // To initialize the DomainParser only once for all tests
        public DomainParserFixture()
        {
            // Use the real public suffix list for testing
            var ruleProvider = new SimpleHttpRuleProvider();
            ruleProvider.BuildAsync().GetAwaiter().GetResult();
            DomainParser = new DomainParser(ruleProvider);
        }

        // Needed for IDisposable
        public void Dispose() { }
    }
}
