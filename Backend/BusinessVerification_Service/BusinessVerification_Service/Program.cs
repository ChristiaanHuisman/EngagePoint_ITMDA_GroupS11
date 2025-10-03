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

            // Register DomainParser as a singleton
            builder.Services.AddSingleton<IDomainParser>(sp =>
            {
                var ruleProvider = new SimpleHttpRuleProvider();
                ruleProvider.BuildAsync().GetAwaiter().GetResult();
                return new DomainParser(ruleProvider);
            });

            // Add services to the container.
            builder.Services.AddScoped<DomainVerificationService>();

            builder.Services.AddControllers();
            // Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();

            var app = builder.Build();

            // Configure the HTTP request pipeline.
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
