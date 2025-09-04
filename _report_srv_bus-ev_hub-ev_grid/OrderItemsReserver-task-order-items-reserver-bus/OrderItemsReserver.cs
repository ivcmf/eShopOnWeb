using Azure.Core;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Text;

namespace OrderItemsReserver
{
    public class OrderItemsReserver
    {
        private readonly BlobContainerClient _container;
        private readonly IHttpClientFactory _httpFactory;
        private readonly ILogger<OrderItemsReserver> _log;
        private readonly string? _logicAppUrl;


        public OrderItemsReserver(IConfiguration cfg,
        ILogger<OrderItemsReserver> log,
        IHttpClientFactory httpFactory)
        {
            _log = log;
            _httpFactory = httpFactory;
            _logicAppUrl = cfg["FallbackLogicAppUrl"]; // required for fallback


            var blobConn = cfg["BlobConnection"];
            var containerName = cfg["BlobContainer"] ?? "orders";


            // SDK‑level retries for Blob client (3 attempts, exponential)
            var blobOpts = new BlobClientOptions
            {
                Retry = {
                    Mode = RetryMode.Exponential,
                    MaxRetries = 3,
                    Delay = TimeSpan.FromSeconds(1),
                    MaxDelay = TimeSpan.FromSeconds(10)
                }
            };


            _container = new BlobContainerClient(blobConn, containerName, blobOpts);
        }


        [Function("OrderItemsReserver")]
        public async Task Run(
        [ServiceBusTrigger("orderreserve", Connection = "ServiceBusConnection")] ServiceBusReceivedMessage message,
        FunctionContext context,
        CancellationToken ct)
        {
            string body = message.Body.ToString();
            string orderId = message.ApplicationProperties.TryGetValue("orderId", out var v)
            ? v?.ToString() ?? Guid.NewGuid().ToString("N")
            : Guid.NewGuid().ToString("N");


            string blobName = $"{DateTime.UtcNow:yyyyMMddHHmmssfff}-{orderId}-{message.MessageId}.json";

            try
            {
                await _container.CreateIfNotExistsAsync(cancellationToken: ct);
                var blob = _container.GetBlobClient(blobName);


                using var ms = new MemoryStream(Encoding.UTF8.GetBytes(body));
                await blob.UploadAsync(ms, overwrite: true, cancellationToken: ct);


                _log.LogInformation("Order {OrderId} saved to blob {BlobName}.", orderId, blobName);
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "Blob upload failed for {OrderId}; invoking fallback.", orderId);


                if (!string.IsNullOrWhiteSpace(_logicAppUrl))
                {
                    var http = _httpFactory.CreateClient();
                    using var content = new StringContent(body, Encoding.UTF8, "application/json");
                    var resp = await http.PostAsync(_logicAppUrl, content, ct);
                    resp.EnsureSuccessStatusCode();
                    _log.LogWarning("Fallback sent to Logic App for Order {OrderId}.", orderId);
                }
                else
                {
                    // No fallback configured → surface the failure so SB can dead-letter per queue policy
                    throw;
                }
            }
        }
    }
}