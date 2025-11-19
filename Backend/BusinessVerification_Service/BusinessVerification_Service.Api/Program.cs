using BusinessVerification_Service.Api.Helpers;
using BusinessVerification_Service.Api.Interfaces.HelpersInterfaces;
using BusinessVerification_Service.Api.Interfaces.ServicesInterfaces;
using BusinessVerification_Service.Api.Models;
using BusinessVerification_Service.Api.Services;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using Google.Cloud.Firestore.V1;
using Nager.PublicSuffix;
using Nager.PublicSuffix.RuleProviders;
using System.Text.Json;

namespace BusinessVerification_Service.Api
{
    public class Program
    {
        // Essential actions like loading credentials, connecting to databases, and
        // downloading content is done in the startup of the service so that if anything
        // important fails the service will not start up and cause other errors during
        // logic runtime
        public static async Task Main(string[] args)
        {
            WebApplicationBuilder builder = WebApplication.CreateBuilder(args);

            try
            {
                // Get service information from environemnt variable SERVICE_INFORMATION
                //
                // Else retrieve the Google credentials from the file reference
                // in appsettings.Development.json
                string serviceInformationPath = Environment.GetEnvironmentVariable("SERVICE_INFORMATION")
                    ?? builder.Configuration["Service:ServiceInformationPath"];
                if (File.Exists(serviceInformationPath))
                {
                    string serviceInformationContent = await File.ReadAllTextAsync(serviceInformationPath);
                    ServiceInformationModel serviceInformation = JsonSerializer
                        .Deserialize<ServiceInformationModel>(serviceInformationContent);
                    builder.Services.AddSingleton(serviceInformation);
                }
                Console.WriteLine($"Startup: Successfully retrieved service information.");
            }
            catch (Exception exception)
            {
                // Stop the program if the service information cannot be loaded
                Console.WriteLine($"Startup: Failed to retrieve service information: " +
                    $"{exception.Message}");
                throw;
            }

            try
            {
                // Get email settings from environemnt variable EMAIL_SETTINGS
                //
                // Else retrieve the Google credentials from the file reference
                // in appsettings.Development.json
                string emailSettingsPath = Environment.GetEnvironmentVariable("EMAIL_SETTINGS")
                    ?? builder.Configuration["Email:EmailSettingsPath"];
                if (File.Exists(emailSettingsPath))
                {
                    string emailSettingsContent = await File.ReadAllTextAsync(emailSettingsPath);
                    EmailSettingsModel emailSettings = JsonSerializer
                        .Deserialize<EmailSettingsModel>(emailSettingsContent);
                    builder.Services.AddSingleton(emailSettings);
                }
                Console.WriteLine($"Startup: Successfully retrieved email settings.");
            }
            catch (Exception exception)
            {
                // Stop the program if the email settings cannot be loaded
                Console.WriteLine($"Startup: Failed to retrieve email settings: " +
                    $"{exception.Message}");
                throw;
            }

            // These variables need to be used later on outside of this try catch block
            string credentialPath, projectId;
            GoogleCredential googleCredential;
            try
            {
                // Get Googe credentials from environemnt variable GOOGLE_APPLICATION_CREDENTIALS
                //
                // Else retrieve the Google credentials from the file reference
                // in appsettings.Development.json
                //
                // The same goes for the project ID
                credentialPath = Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS")
                    ?? builder.Configuration["Firestore:CredentialsPath"];
                projectId = Environment.GetEnvironmentVariable("FIREBASE_PROJECT_ID")
                    ?? builder.Configuration["Firestore:ProjectId"];
                googleCredential = GoogleCredential.FromFile(credentialPath);
                Console.WriteLine($"Startup: Successfully retrieved Google credentials.");
            }
            catch (Exception exception)
            {
                // Stop the program if the Google credentials cannot be loaded
                Console.WriteLine($"Startup: Failed to retrieve Google credentials: " +
                    $"{exception.Message}");
                throw;
            }

            try
            {
                // Initialize Firebase admin so that it can be used
                // anywhere in the app
                //
                // Protect against duplicates if Firebase app restarts
                if (FirebaseAdmin.FirebaseApp.DefaultInstance == null)
                {
                    FirebaseAdmin.FirebaseApp.Create(new FirebaseAdmin.AppOptions
                    {
                        Credential = googleCredential
                    });
                }
                Console.WriteLine($"Startup: Successfully initialized Firebase admin.");
            }
            catch (Exception exception)
            {
                // Stop the program if Firebase admin cannot be initialized
                Console.WriteLine($"Startup: Failed to initialize Firebase admin: " +
                    $"{exception.Message}");
                throw;
            }

            try
            {
                // Register FirestoreDb as a Singleton
                //
                // Only done once per application lifetime as it is for prototyping purposes
                //
                // Having a periodic refresh of the credentials can be added in future
                // versions of the API for performance improvements when the application
                // scales to a more permanent hosting solution
                FirestoreClient firestoreClient = new FirestoreClientBuilder
                {
                    Credential = googleCredential
                }.Build();
                FirestoreDb firestoreDb = FirestoreDb.Create(projectId,
                    client: firestoreClient);
                builder.Services.AddSingleton(firestoreDb);
                Console.WriteLine($"Startup: Successfully connected to Firestore.");
            }
            catch (Exception exception)
            {
                // Stop the program if the connection to Firestore fails
                Console.WriteLine($"Startup: Failed to connect to Firestore: " +
                    $"{exception.Message}");
                throw;
            }

            try
            {
                // Register IDomainParser as a Singleton asynchronously
                //
                // Only done once per application lifetime as it is for prototyping purposes
                //
                // Caching the public suffix list periodically can be added in future
                // verisons for performance improvements when the application scales
                // to a more permanent hosting solution
                SimpleHttpRuleProvider ruleProvider = new();
                await ruleProvider.BuildAsync();
                DomainParser domainParser = new(ruleProvider);
                builder.Services.AddSingleton<IDomainParser>(domainParser);
                Console.WriteLine($"Startup: Successfully downloaded the public suffix list.");
            }
            catch (Exception exception)
            {
                // Stop the program if getting the public suffix list fails
                Console.WriteLine($"Startup: Failed to download the public suffix list: " +
                    $"{exception.Message}");
                throw;
            }

            // Add interfaces of services and helpers to the container
            builder.Services.AddSingleton<IFirebaseHelper, FirebaseHelper>();
            builder.Services.AddSingleton<IFirestoreService, FirestoreService>();
            builder.Services.AddSingleton<IDomainNameHelper, DomainNameHelper>();
            builder.Services.AddSingleton<IWebsiteAddressHelper, WebsiteAddressHelper>();
            builder.Services.AddSingleton<ITokenGeneratorHelper, TokenGeneratorHelper>();
            builder.Services.AddSingleton<IEmailHelper, EmailHelper>();
            builder.Services.AddSingleton<INormalizationAndValidationHelper,
                NormalizationAndValidationHelper>();
            builder.Services.AddScoped<IEmailVerificationService, EmailVerificationService>();
            builder.Services.AddScoped<IBusinessVerificationService,
                BusinessVerificationService>();

            builder.Services.AddControllers();
            builder.Services.AddEndpointsApiExplorer();
            builder.Services.AddSwaggerGen();
            builder.Services.AddHealthChecks();

            // Enable CORS
            builder.Services.AddCors(options =>
            {
                options.AddPolicy("AllowAll",
                    policy => policy
                    .AllowAnyOrigin()
                    .AllowAnyHeader()
                    .AllowAnyMethod()
                );
            });

            WebApplication app = builder.Build();

            // Use CORS
            app.UseCors("AllowAll");

            // Configure the HTTP request pipeline
            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseAuthorization();

            // Global middleware to prevent caching for all endpoints
            app.Use(async (context, next) =>
            {
                context.Response.Headers.CacheControl = "no-store, no-cache, " +
                    "must-revalidate, proxy-revalidate";
                context.Response.Headers.Pragma = "no-cache";
                context.Response.Headers.Expires = "0";
                context.Response.Headers["Surrogate-Control"] = "no-store";
                await next();
            });

            // Serve static files from wwwroot
            app.UseStaticFiles();

            app.MapControllers();
            app.MapHealthChecks("/health");

            Console.WriteLine($"Startup: Completed.");

            app.Run();
        }
    }
}
