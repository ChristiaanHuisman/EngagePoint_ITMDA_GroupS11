namespace BusinessVerification_Service.Api.Dtos
{
    // For returning parsed doamin info
    public class ParsedDomainDto
    {
        public string? registrableDomain { get; set; }

        public string? topLevelDomain { get; set; }

        public string? domain { get; set; }
    }
}
