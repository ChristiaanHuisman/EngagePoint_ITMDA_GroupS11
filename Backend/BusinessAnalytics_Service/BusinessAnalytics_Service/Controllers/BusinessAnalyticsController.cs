using Microsoft.AspNetCore.Mvc;
using BusinessAnalytics_Service.Services;
using Backend.BusinessAnalytics_Service.BusinessAnalytics_Service.Services;


[ApiController]
[Route("api/[controller]")]

public class AnalyticsController : ControllerBase
{
    private readonly GoogleAnalyticsService _Analytics;
    private readonly PdfGeneratorService _pdfGenerator;

    public AnalyticsController(GoogleAnalyticsService analyticsService, PdfGeneratorService pdfGenerator) //analytics controller class constructor
    {
        _Analytics = analyticsService;
        _pdfGenerator = pdfGenerator;
    }

    //The following 4 methods return Json data for the respective analytics endpoints
    [HttpGet("ViewsPerPost/{businessID}/{startDate}/{endDate}")]
    public async Task<IActionResult> GetPostViews(string businessID, string startDate, string endDate)
    {
        var result = await _Analytics.ViewsPerPostAsync(businessID, startDate, endDate);  //calls the service method to get views per post data
        return Ok(result); //returns the data as an HTTP 200 response in JSON format
    }

    [HttpGet("VisitorsPerAccount/{businessID}/{startDate}/{endDate}")]
    public async Task<IActionResult> GetVisitorsPerAccount(string businessID, string startDate, string endDate)
    {
        var result = await _Analytics.UniqueBusinessVisitorsAsync(businessID, startDate, endDate);  //calls the service method to get visitors per account data
        return Ok(result); //returns the data as an HTTP 200 response in JSON format
    }

    [HttpGet("ClickThrough/{businessID}/{startDate}/{endDate}")]
    public async Task<IActionResult> GetClickThroughs(string businessID, string startDate, string endDate)
    {
        var result = await _Analytics.ClickThroughsAsync(businessID, startDate, endDate);  //calls the service method to get click through data
        return Ok(result); //returns the data as an HTTP 200 response in JSON format
    }

    [HttpGet("FollowsByDay/{businessID}/{startDate}/{endDate}")]
    public async Task<IActionResult> GetFollowByDay(string businessID, string startDate, string endDate)
    {
        var result = await _Analytics.FollowByDayAsync(businessID, startDate, endDate);  //calls the service method to get click through data
        return Ok(result); //returns the data as an HTTP 200 response in JSON format
    }

    //the following 4 methods generate and return PDF reports for the respective analytics endpoints
    [HttpGet("ViewsPerPost/{businessID}/{startDate}/{endDate}/pdf")]
    public async Task<IActionResult> GetViewPerPostPdf(string businessID, string startDate, string endDate)
    {
        var result = await _Analytics.ViewsPerPostAsync(businessID, startDate, endDate);  //calls the service method to get views per post data
        var pdfBytes = await _pdfGenerator.GenerateViewPerPostPdf(result); //generates the PDF using the PdfGeneratorService
        return File(pdfBytes, "application/pdf", "ViewPerPostReport.pdf"); //returns the PDF as a file response
    }

    [HttpGet("VisitorsPerAccount/{businessID}/{startDate}/{endDate}/pdf")]
    public async Task<IActionResult> GetVisitorsPerAccountPdf(string businessID, string startDate, string endDate)
    {
        var result = await _Analytics.UniqueBusinessVisitorsAsync(businessID, startDate, endDate);  //calls the service method to get views per post data
        var pdfBytes = await _pdfGenerator.GenerateVisitorsPerAccountPdf(result); //generates the PDF using the PdfGeneratorService
        return File(pdfBytes, "application/pdf", "UniqueVisitorsReport.pdf"); //returns the PDF as a file response
    }

    [HttpGet("ClickThrough/{businessID}/{startDate}/{endDate}/pdf")]
    public async Task<IActionResult> GetClickThroughPdf(string businessID, string startDate, string endDate)
    {
        var result = await _Analytics.ClickThroughsAsync(businessID, startDate, endDate);  //calls the service method to get views per post data
        var pdfBytes = await _pdfGenerator.GenerateClickThroughPdf(result); //generates the PDF using the PdfGeneratorService
        return File(pdfBytes, "application/pdf", "ClickThroughReport.pdf"); //returns the PDF as a file response
    }

    [HttpGet("FollowsByDay/{businessID}/{startDate}/{endDate}/pdf")]
    public async Task<IActionResult> GetFollowersByDayPdf(string businessID, string startDate, string endDate)
    {
        var result = await _Analytics.FollowByDayAsync(businessID, startDate, endDate);  //calls the service method to get views per post data
        var pdfBytes = await _pdfGenerator.GenerateFollowsByDayPdf(result); //generates the PDF using the PdfGeneratorService
        return File(pdfBytes, "application/pdf", "NewFollowersReport.pdf"); //returns the PDF as a file response
    }
}

