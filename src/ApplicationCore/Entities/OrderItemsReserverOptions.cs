namespace Microsoft.eShopWeb.ApplicationCore.Entities;
public sealed class OrderItemsReserverOptions
{
    public string Connection { get; set; } = string.Empty;
    public string Queue { get; set; } = "orderreserve";
}
