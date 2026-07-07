FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy csproj and restore as distinct layers
COPY RentLanka.Api.csproj .
RUN dotnet restore

# Copy everything else and build release
COPY . .
RUN dotnet publish -c Release -o /app/publish

# Run runtime image
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

# Expose port 8080 (standard for Azure Linux App Service containers)
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "RentLanka.Api.dll"]
