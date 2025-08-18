using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace Microsoft.eShopWeb.ApplicationCore.Interfaces;

public interface IOrderReserveClient
{
    Task SendAsync(string orderId, IEnumerable<(string itemId, int qty)> items, CancellationToken ct = default);
}
