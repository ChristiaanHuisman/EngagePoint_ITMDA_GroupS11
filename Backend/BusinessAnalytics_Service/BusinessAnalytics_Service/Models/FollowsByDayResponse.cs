namespace Backend.BusinessAnalytics_Service.BusinessAnalytics_Service.Models
{
    public class FollowsByDayResponse //DTO to return new follows by day data
    {
        public string businessID { get; set; } 
        public string StartDate { get; set; }
        public string EndDate { get; set; }
        public List<FollowsByDayDatapoint> DataPoints { get; set; }
    }

    public class FollowsByDayDatapoint
    {
        public string Date { get; set; } 
        public int Follows { get; set; }
    }
}