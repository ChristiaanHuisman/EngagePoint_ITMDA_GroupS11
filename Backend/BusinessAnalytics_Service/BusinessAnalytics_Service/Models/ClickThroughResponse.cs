namespace Backend.BusinessAnalytics_Service.BusinessAnalytics_Service.Models
{
    public class ClickThroughResponse //DTO to return click through data
    {
        public string businessID { get; set; } 
        public string StartDate { get; set; }
        public string EndDate { get; set; }
        public List<ClickThroughDatapoint> DataPoints { get; set; }
    }

    public class ClickThroughDatapoint
    {
        public string Date { get; set; } 
        public int Visitors { get; set; }
    }
}