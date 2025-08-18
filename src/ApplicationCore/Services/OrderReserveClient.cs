using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Microsoft.eShopWeb.ApplicationCore.Entities;
using Microsoft.eShopWeb.ApplicationCore.Interfaces;
using System.Collections.Generic;

namespace Microsoft.eShopWeb.ApplicationCore.Services;

public class OrderReserveClient : IOrderReserveClient
{
    private readonly HttpClient _http;
    private readonly OrderReserveOptions _opt;
    private readonly ILogger<OrderReserveClient> _logger;

    public OrderReserveClient(HttpClient http, IOptions<OrderReserveOptions> opt, ILogger<OrderReserveClient> logger)
    {
        _http = http;
        _opt = opt.Value;
        _logger = logger;
    }

    public async Task SendAsync(string orderId, IEnumerable<(string itemId, int qty)> items, CancellationToken ct = default)
    {
        var url = _opt.FunctionUrl ?? throw new System.InvalidOperationException("OrderReserve:FunctionUrl is not set");
        var key = _opt.FunctionKey; 

        var payload = new
        {
            orderId,
            items = items.Select(x => new { itemId = x.itemId, quantity = x.qty }).ToArray()
        };

        using var req = new HttpRequestMessage(HttpMethod.Post, url);
        req.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
        if (!string.IsNullOrWhiteSpace(key))
            req.Headers.Add("x-functions-key", key); 

        var res = await _http.SendAsync(req, ct);
        if (!res.IsSuccessStatusCode)
        {
            var body = await res.Content.ReadAsStringAsync(ct);
            _logger.LogWarning("Reserve call failed. Status: {Status}. Body: {Body}", (int)res.StatusCode, body);
            res.EnsureSuccessStatusCode(); 
        }
        else
        {
            _logger.LogInformation("Reserve queued for order {OrderId}", orderId);
        }
    }

}
