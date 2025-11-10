namespace Backend.BusinessAnalytics_Service.BusinessAnalytics_Service.Models
{
    public class VisitorsPerAccountResponse //DTO to return visitors per account data
    {
        public string businessID { get; set; } 
        public string StartDate { get; set; }
        public string EndDate { get; set; }
        public List<visitorPerAccountDatapoint> DataPoints { get; set; }
    }

    public class visitorPerAccountDatapoint
    {
        public string Date { get; set; } 
        public int Visitors { get; set; }
    }
}