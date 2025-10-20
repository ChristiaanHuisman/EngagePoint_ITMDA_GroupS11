using BusinessVerification_Service.Interfaces;
using BusinessVerification_Service.Services;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using Google.Cloud.Firestore.V1;
using Nager.PublicSuffix;
using Nager.PublicSuffix.RuleProviders;

namespace BusinessVerification_Service
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Stop the program if getting the public suffix list fails
            try
            {
                // Register IDomainParser as a Singleton asynchronously
                // Only done once per application lifetime as it is for prototyping purposes
                // Caching the public suffix list can be added in future verisons, 
                // for performance improvements when the application scales to a more permanent hosting solution
                var ruleProvider = new SimpleHttpRuleProvider();
                await ruleProvider.BuildAsync();
                var domainParser = new DomainParser(ruleProvider);
                builder.Services.AddSingleton<IDomainParser>(domainParser);
            }
            catch
            {
                throw;
            }

            // Stop the program if the connection to Firestore fails
            try
            {
                // Register FirestoreDb as a Singleton
                // Only done once per application lifetime as it is for prototyping purposes
                // Having periodic refresh of the credentials can be added in future versions, 
                // for performance improvements when the application scales to a more permanent hosting solution
                var credentialPath = builder.Configuration["Firestore:CredentialsPath"];
                var projectId = builder.Configuration["Firestore:ProjectId"];
                var googleCredential = GoogleCredential.FromFile(credentialPath);
                var firestoreClient = new FirestoreClientBuilder
                {
                    Credential = googleCredential
                }.Build();
                var firestoreDb = FirestoreDb.Create(projectId, client: firestoreClient);
                builder.Services.AddSingleton(firestoreDb);
            }
            catch
            {
                throw;
            }
            
            // Register interface services
            builder.Services.AddScoped<IDomainVerificationService, DomainVerificationService>();
            builder.Services.AddScoped<IFirestoreFunctionsService, FirestoreFunctionsService>();

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
