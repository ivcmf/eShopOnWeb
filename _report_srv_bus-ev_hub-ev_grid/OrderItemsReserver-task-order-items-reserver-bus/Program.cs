using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.Azure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var builder = FunctionsApplication.CreateBuilder(args);


// Load local.settings.json when running locally
builder.Configuration
.AddJsonFile("local.settings.json", optional: true, reloadOnChange: true)
.AddEnvironmentVariables();


// DI: BlobService client + HttpClient for Logic App
builder.Services.AddAzureClients(b =>
{
    var blobConn = builder.Configuration["Blob__Connection"];
    if (!string.IsNullOrWhiteSpace(blobConn))
    {
        b.AddBlobServiceClient(blobConn);
    }
});


builder.Services.AddHttpClient();


// App Insights (optional but recommended)
builder.Services.AddApplicationInsightsTelemetryWorkerService();
builder.Services.ConfigureFunctionsApplicationInsights();


builder.Build().Run();