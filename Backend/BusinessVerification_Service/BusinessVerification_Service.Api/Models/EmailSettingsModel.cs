namespace BusinessVerification_Service.Api.Models
{
    // Model for sendnig transactional emails, property values are
    // retrieved from engagepoint-email-smtpsettings.json and
    // initialized in Program.cs
    public class EmailSettingsModel
    {
        public string senderName { get; set; }

        public string senderEmail { get; set; }

        public string appPassword { get; set; }

        public string smtpServer { get; set; }

        public int port { get; set; }
    }
}
