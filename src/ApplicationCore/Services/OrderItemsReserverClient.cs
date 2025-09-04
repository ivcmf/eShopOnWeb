using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Microsoft.eShopWeb.ApplicationCore.Entities;
using Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;
using Microsoft.eShopWeb.ApplicationCore.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

public sealed class OrderItemsReserverClient : IOrderItemsReserver
{
    private readonly ServiceBusClient _client;
    private readonly ServiceBusSender _sender;
    private readonly ILogger<OrderItemsReserverClient> _logger;


    public OrderItemsReserverClient(IOptions<OrderItemsReserverOptions> opt,
    ILogger<OrderItemsReserverClient> logger)
    {
        _logger = logger;
        var o = opt.Value;
        _client = new ServiceBusClient(o.Connection);
        _sender = _client.CreateSender(o.Queue);
    }

    string IOrderItemsReserver.Connection => throw new System.NotImplementedException();

    string IOrderItemsReserver.Queue => throw new System.NotImplementedException();

    public async Task SendAsync(Order order, CancellationToken ct = default)
    {
        var payload = new
        {
            orderId = order.Id,
            items = order.OrderItems.Select(i => new
            {
                itemId = i.ItemOrdered.CatalogItemId,
                quantity = i.Units
            })
        };


        var json = JsonSerializer.Serialize(payload);
        var message = new ServiceBusMessage(json)
        {
            ContentType = "application/json",
            Subject = "ReserveItems",
            CorrelationId = order.Id.ToString()
        };
        message.ApplicationProperties["tenant"] = "eshop";

       
        await _sender.SendMessageAsync(message, ct);
        _logger.LogInformation("Sent ReserveItems for Order {OrderId}", order.Id);
    }
}
