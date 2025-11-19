namespace BusinessVerification_Service.Api.Interfaces.HelpersInterfaces
{
    // Include methods from the helper
    public interface IEmailHelper
    {
        string BuildVerificationEmailHtml(string name, string verificationLink);

        Task SendEmailSmtp(string recipientEmail, string recipientName,
            string emailSubject, string htmlContent);
    }
}
