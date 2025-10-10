using BusinessVerification_Service.Interfaces;
using BusinessVerification_Service.Services;
using Nager.PublicSuffix;
using Nager.PublicSuffix.RuleProviders;

namespace BusinessVerification_Service
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Register IDomainParser as a Singleton
            builder.Services.AddSingleton<IDomainParser>(sp =>
            {
                // Use the real domain parser to download the newest public suffix list
                var ruleProvider = new SimpleHttpRuleProvider();
                ruleProvider.BuildAsync().GetAwaiter().GetResult();
                return new DomainParser(ruleProvider);
            });

            // Register interface services
            builder.Services.AddScoped<IDomainVerificationService, DomainVerificationService>();

            builder.Services.AddControllers();
            // Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            var app = builder.Build();

            // Configure the HTTP request pipeline
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseAuthorization();


            app.MapControllers();

            app.Run();
        }
    }
}
