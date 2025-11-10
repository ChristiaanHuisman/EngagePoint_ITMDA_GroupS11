namespace Backend.BusinessAnalytics_Service.BusinessAnalytics_Service.Models
{
    public class ViewPerPostResponse //DTO to return views per post data
    {
        public string businessID { get; set; } 
        public string StartDate { get; set; }
        public string EndDate { get; set; }
        public List<viewPerPostDatapoint> DataPoints { get; set; }
    }

    public class viewPerPostDatapoint
    {
        public string PostName { get; set; } //change to name
        public int Views { get; set; }
    }
}