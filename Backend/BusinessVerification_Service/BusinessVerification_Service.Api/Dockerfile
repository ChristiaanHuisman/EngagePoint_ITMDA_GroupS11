# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY BusinessVerification_Service.Api.csproj .
RUN dotnet restore BusinessVerification_Service.Api.csproj

# Copy all source code
COPY . .

# Publish the project
RUN dotnet publish BusinessVerification_Service.Api.csproj -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Copy published output from build stage
COPY --from=build /app/publish .

# Expose the port that the app runs on
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

# Entry point
ENTRYPOINT ["dotnet", "BusinessVerification_Service.Api.dll"]