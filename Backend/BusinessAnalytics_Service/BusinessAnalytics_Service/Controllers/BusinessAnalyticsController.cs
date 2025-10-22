using Microsoft.AspNetCore.Mvc;
using Google.Apis.Auth.OAuth2;
using Google.Analytics.Data.V1Beta;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.ComponentModel.DataAnnotations;
using BusinessAnalytics_Service.Services;


[ApiController]
[Route("api/[controller]")]

public class AnalyticsController : ControllerBase
{
    private readonly GoogleAnalyticsService _Analytics;

    public AnalyticsController(GoogleAnalyticsService analyticsService) //analytics controller class constructor
    {
        _Analytics = analyticsService;
    }

    [HttpGet("ViewsPerPost/{businessID}/{startDate}/{endDate}")]
    public async Task<IActionResult> GetPostViews(string businessID, string startDate, string endDate)
    {
        var result = await _Analytics.ViewsPerPostAsync(businessID, startDate, endDate);  //calls the service method to get views per post data
        return Ok(result); //returns the data as an HTTP 200 response in JSON format
    }
}
