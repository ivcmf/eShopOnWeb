using System;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.eShopWeb.ApplicationCore.Entities;
using Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;
using Microsoft.eShopWeb.ApplicationCore.Interfaces;

namespace Microsoft.eShopWeb.ApplicationCore.Services;

public class DeliveryOrderService : IDeliveryOrder
{
    private readonly HttpClient _http;
    private readonly DeliveryOrder _opt;
    private readonly ILogger<DeliveryOrderService> _logger;

    public DeliveryOrderService(HttpClient http, IOptions<DeliveryOrder> opt, ILogger<DeliveryOrderService> logger)
    {
        _http = http;
        _opt = opt.Value;
        _logger = logger;
    }

    public async Task SendAsync(Order order, CancellationToken ct = default)
    {
        var url = _opt.FunctionUrl ?? throw new InvalidOperationException("DeliveryOrder:FunctionUrl is not set");
        var key = _opt.FunctionKey;

        var payload = new
        {
            id = Guid.NewGuid().ToString(),
            orderId = order.Id.ToString(),
            createdUtc = DateTime.UtcNow,
            customerId = order.BuyerId,
            shippingAddress = new
            {
                name = order.BuyerId, 
                country = order.ShipToAddress.Country,
                city = order.ShipToAddress.City,
                zip = order.ShipToAddress.ZipCode,
                line1 = order.ShipToAddress.Street
            },
            items = order.OrderItems.Select(i => new
            {
                productId = i.ItemOrdered.CatalogItemId,
                name = i.ItemOrdered.ProductName,
                qty = i.Units,
                unitPrice = i.UnitPrice
            }),
            finalPrice = order.Total()
        };

        using var req = new HttpRequestMessage(HttpMethod.Post, url);
        req.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
        if (!string.IsNullOrWhiteSpace(key))
            req.Headers.Add("x-functions-key", key);

        _logger.LogInformation("Calling Delivery Function for order {OrderId} at {Url}", order.Id, url);

        var res = await _http.SendAsync(req, ct);

        if (!res.IsSuccessStatusCode)
        {
            var body = await res.Content.ReadAsStringAsync(ct);
            _logger.LogWarning("Delivery call failed. Status: {Status}. Body: {Body}", (int)res.StatusCode, body);
            res.EnsureSuccessStatusCode();
        }

        _logger.LogInformation("Delivery document queued for order {OrderId}", order.Id);
    }
}
