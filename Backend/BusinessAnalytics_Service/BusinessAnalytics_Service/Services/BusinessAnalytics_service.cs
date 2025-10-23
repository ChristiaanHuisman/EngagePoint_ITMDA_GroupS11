using Google.Analytics.Data.V1Beta;
using Google.Apis.Auth.OAuth2;
using Backend.BusinessAnalytics_Service.BusinessAnalytics_Service.Models;


namespace BusinessAnalytics_Service.Services
{

    public class GoogleAnalyticsService
    {
        private readonly BetaAnalyticsDataClient _analyticsDataClient;

        public GoogleAnalyticsService()//used to connect to the Google Analytics Data API
        {

            GoogleCredential credential = null;

        // Prefer Application Default Credentials (Cloud Run or GCE will provide these when a service account is attached)
        try
        {
            credential = GoogleCredential.GetApplicationDefault().CreateScoped(BetaAnalyticsDataClient.DefaultScopes);
        }
        catch
        {
            // If ADC not available (e.g., local dev), optionally read JSON from env var GOOGLE_SERVICE_ACCOUNT_JSON.
            var json = Environment.GetEnvironmentVariable("GOOGLE_SERVICE_ACCOUNT_JSON");
            if (!string.IsNullOrEmpty(json))
            {
                credential = GoogleCredential.FromJson(json).CreateScoped(BetaAnalyticsDataClient.DefaultScopes);
            }
            else
            {
                throw new InvalidOperationException("No Google credentials found. Set ADC or GOOGLE_SERVICE_ACCOUNT_JSON.");
            }
        }

        _analyticsDataClient = new BetaAnalyticsDataClientBuilder
        {
            Credential = credential
        }.Build();//builds the Analytics Data API client using the provided credentials


        }

        public async Task<ViewPerPostResponse> ViewsPerPostAsync(string businessID, string startDate, string endDate) //Method to return the total views per post for a given business
        {
            RunReportRequest request = new RunReportRequest
            {
                Property = "properties/508197648", //GA4 property ID. For this API will always remain the same 
                Dimensions = { new Dimension { Name = "customEvent:post_name" } }, //tells the API to group data by post ID (Note ""customEvent:"" is required for custom dimensions and events)

                Metrics = { new Metric { Name = "eventCount" } },  //returns the total number of events (views) for each post

                DimensionFilter = new FilterExpression //filters data based on business ID
                {
                    Filter = new Filter
                    {
                        FieldName = "customEvent:business_id",
                        StringFilter = new Filter.Types.StringFilter
                        {
                            MatchType = Filter.Types.StringFilter.Types.MatchType.Exact,
                            Value = businessID
                        }
                    }
                },

                DateRanges = { new DateRange { StartDate = startDate, EndDate = endDate } }
            };

            RunReportResponse response = await _analyticsDataClient.RunReportAsync(request); //uses the client created in the previous function to access data

            var AnalyticsResponse = new ViewPerPostResponse
            {
                businessID = businessID,
                StartDate = startDate,
                EndDate = endDate,
                DataPoints = response.Rows.Select(d => new viewPerPostDatapoint
                {
                    PostName = d.DimensionValues[0].Value,
                    Views = int.Parse(d.MetricValues[0].Value)
                }).ToList()
            };

            return AnalyticsResponse;
        }


        public async Task<VisitorsPerAccountResponse> UniqueBusinessVisitorsAsync(string businessID, string startDate, string endDate) //Method to return number of unique visitors a business receieved per day
        {
            RunReportRequest request = new RunReportRequest
            {
                Property = "properties/508197648", //GA4 property ID. For this API will always remain the same 
                Dimensions = { new Dimension { Name = "date" } }, //receives the date

                Metrics = { new Metric { Name = "activeUsers" } },  //returns the total number of events (views) for each account

                DimensionFilter = new FilterExpression
                {
                    AndGroup = new FilterExpressionList
                    {
                        Expressions =
                        {
                            new FilterExpression //filters data based on business ID
                            {
                                Filter = new Filter
                                {
                                    FieldName = "customEvent:viewed_business_id",
                                    StringFilter = new Filter.Types.StringFilter
                                    {
                                        MatchType = Filter.Types.StringFilter.Types.MatchType.Exact,
                                        Value = businessID
                                    }
                                }
                            },

                            new FilterExpression //ensures it only accounts for "View_business_profile" events
                            {
                                Filter = new Filter
                                {
                                    FieldName = "eventName",
                                    StringFilter = new Filter.Types.StringFilter
                                    {
                                        MatchType = Filter.Types.StringFilter.Types.MatchType.Exact,
                                        Value = "View_business_profile"
                                    }
                                }
                            }
                        }

                    }
                },
                DateRanges = { new DateRange { StartDate = startDate, EndDate = endDate } },

                OrderBys =   //ensures data is ordered by date in ascending order
                {
                    new OrderBy
                    {
                        Dimension = new OrderBy.Types.DimensionOrderBy  
                        {
                            DimensionName="date"
                        },
                        Desc=false
                    }
                }
            };

            var response = await _analyticsDataClient.RunReportAsync(request); //uses the client created in the previous function to access data

            var AnalyticsResponse = new VisitorsPerAccountResponse
            {
                businessID = businessID,
                StartDate = startDate,
                EndDate = endDate,
                DataPoints = response.Rows.Select(d => new visitorPerAccountDatapoint
                {
                    Date = d.DimensionValues[0].Value,
                    Visitors = int.Parse(d.MetricValues[0].Value)
                }).ToList()
            };

            return AnalyticsResponse;

        }

        public async Task<ClickThroughResponse> ClickThroughsAsync(string businessID, string startDate, string endDate) //Method to return total click throughs to a business's website
        {
            RunReportRequest request = new RunReportRequest
            {
                Property = "properties/508197648", //GA4 property ID. For this API will always remain the same 

                Dimensions = { new Dimension { Name = "date" } },

                Metrics = { new Metric { Name = "eventCount" } },  //returns the total number of events (click throughs)

                DimensionFilter = new FilterExpression
                {
                    AndGroup = new FilterExpressionList
                    {
                        Expressions =
                        {
                            new FilterExpression //filters data based on business ID
                            {
                                Filter = new Filter
                                {
                                    FieldName = "customEvent:business_id",
                                    StringFilter = new Filter.Types.StringFilter
                                    {
                                        MatchType = Filter.Types.StringFilter.Types.MatchType.Exact,
                                        Value = businessID
                                    }
                                }
                            },

                            new FilterExpression //ensures it only accounts for "click_through" events
                            {
                                Filter = new Filter
                                {
                                    FieldName = "eventName",
                                    StringFilter = new Filter.Types.StringFilter
                                    {
                                        MatchType = Filter.Types.StringFilter.Types.MatchType.Exact,
                                        Value = "click_through"
                                    }
                                }
                            }
                        }

                    }
                },
                DateRanges = { new DateRange { StartDate = startDate, EndDate = endDate } },

                OrderBys =    //ensures data is ordered by date in ascending order
                {
                    new OrderBy
                    {
                        Dimension = new OrderBy.Types.DimensionOrderBy
                        {
                            DimensionName="date"
                        },
                        Desc=false
                    }
                }
            };

            var response = await _analyticsDataClient.RunReportAsync(request); //uses the client created in the previous function to access data

            ClickThroughResponse clickThroughs = new ClickThroughResponse
            {
                businessID = businessID,
                StartDate = startDate,
                EndDate = endDate,
                DataPoints = response.Rows.Select(d => new ClickThroughDatapoint
                {
                    Date = d.DimensionValues[0].Value,
                    Visitors = int.Parse(d.MetricValues[0].Value)
                }).ToList()
            };

            return clickThroughs;
        }

        public async Task<FollowsByDayResponse> FollowByDayAsync(string businessID, string startDate, string endDate) //Method to return number of new followers a business received per day
        {
            RunReportRequest request = new RunReportRequest
            {
                Property = "properties/508197648", //GA4 property ID. For this API will always remain the same 

                Dimensions = { new Dimension { Name = "date" } },

                Metrics = { new Metric { Name = "eventCount" } },  //returns the total number of events (click throughs)

                DimensionFilter = new FilterExpression
                {
                    AndGroup = new FilterExpressionList
                    {
                        Expressions =
                        {
                            new FilterExpression //filters data based on business ID
                            {
                                Filter = new Filter
                                {
                                    FieldName = "customEvent:business_id",
                                    StringFilter = new Filter.Types.StringFilter
                                    {
                                        MatchType = Filter.Types.StringFilter.Types.MatchType.Exact,
                                        Value = businessID
                                    }
                                }
                            },

                            new FilterExpression //ensures it only accounts for "business_follow" events
                            {
                                Filter = new Filter
                                {
                                    FieldName = "eventName",
                                    StringFilter = new Filter.Types.StringFilter
                                    {
                                        MatchType = Filter.Types.StringFilter.Types.MatchType.Exact,
                                        Value = "business_follow"
                                    }
                                }
                            }
                        }

                    }
                },
                DateRanges = { new DateRange { StartDate = startDate, EndDate = endDate } },

                OrderBys =      //ensures data is ordered by date in ascending order
                {
                    new OrderBy
                    {
                        Dimension = new OrderBy.Types.DimensionOrderBy
                        {
                            DimensionName="date"
                        },
                        Desc=false
                    }
                }
            };

            var response = await _analyticsDataClient.RunReportAsync(request); //uses the client created in the previous function to access data

            FollowsByDayResponse FollowersByDay = new FollowsByDayResponse
            {
                businessID = businessID,
                StartDate = startDate,
                EndDate = endDate,
                DataPoints = response.Rows.Select(d => new FollowsByDayDatapoint
                {
                    Date = d.DimensionValues[0].Value,
                    Follows = int.Parse(d.MetricValues[0].Value)
                }).ToList()
            };

            return FollowersByDay;
        }
    }
}
