using System.Threading;
using System.Threading.Tasks;
using Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;

namespace Microsoft.eShopWeb.ApplicationCore.Interfaces;
public interface IOrderItemsReserver
{
    string Connection { get; }
    string Queue { get; }

    Task SendAsync(Order order, CancellationToken ct = default);
}
