
namespace BusinessAnalytics_Service
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Add services
            builder.Services.AddControllers();

            // Register your analytics/pdf services for DI
            builder.Services.AddSingleton<BusinessAnalytics_Service.Services.GoogleAnalyticsService>();
            builder.Services.AddSingleton<Backend.BusinessAnalytics_Service.BusinessAnalytics_Service.Services.PdfGeneratorService>();

            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            // Configure CORS
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", policy =>
                {
                    policy.AllowAnyHeader()
                          .AllowAnyMethod()
                          .AllowAnyOrigin();
                });
            });

            var app = builder.Build();

            // Enable Swagger for all environments
            app.UseSwagger();
            app.UseSwaggerUI();

            app.UseCors("AllowAll");
            app.UseAuthorization();
            app.MapControllers();

            app.UseDeveloperExceptionPage();
            
            app.Run();
        }
    }
}