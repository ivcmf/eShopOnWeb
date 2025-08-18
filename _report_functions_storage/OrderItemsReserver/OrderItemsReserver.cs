using System;
using System.IO;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace OrderItemsReserver
{
    public class OrderItemsReserver
    {
        private readonly ILogger<OrderItemsReserver> _logger;
        private readonly BlobContainerClient _container;

        public OrderItemsReserver(ILogger<OrderItemsReserver> logger, IConfiguration config)
        {
            _logger = logger;
            var conn = config["AzureWebJobsStorage"];
            var containerName = config["OrdersContainer"] ?? "orders";
            _container = new BlobContainerClient(conn, containerName);
            _container.CreateIfNotExists();
        }

        public record OrderRequest(string OrderId, OrderLine[] Items);
        public record OrderLine(string ItemId, int Quantity);

        [Function("OrderItemsReserver")]
        public async Task<HttpResponseData> Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = "reserve")] HttpRequestData req)
        {
            try
            {
                using var sr = new StreamReader(req.Body);
                var body = await sr.ReadToEndAsync();
                var order = JsonSerializer.Deserialize<OrderRequest>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                if (order is null || string.IsNullOrWhiteSpace(order.OrderId) || order.Items is null || order.Items.Length == 0)
                {
                    var bad = req.CreateResponse(HttpStatusCode.BadRequest);
                    await bad.WriteStringAsync("Invalid payload");
                    return bad;
                }

                var blobName = $"{order.OrderId}-{DateTime.UtcNow:yyyyMMddHHmmssfff}.json";
                var blob = _container.GetBlobClient(blobName);
                await blob.UploadAsync(new BinaryData(body));

                _logger.LogInformation("Order {OrderId} stored to blob {Blob}", order.OrderId, blobName);
                var ok = req.CreateResponse(HttpStatusCode.Accepted);
                await ok.WriteStringAsync("Accepted");
                return ok;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process order");
                var fail = req.CreateResponse(HttpStatusCode.InternalServerError);
                await fail.WriteStringAsync("Error");
                return fail;
            }
        }
    }
}
