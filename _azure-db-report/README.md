# Report: Azure SQL + CosmosDB Integration for eShopOnWeb

## 1. Task 1 — Azure SQL Database

### Completed steps

- **Azure Infrastructure**

  - Resource group `rg-eshop-db` created.
  - Azure SQL Server + Databases created (`catalogDatabase`, `identityDatabase`).
  - Connection string prepared with user/password.

- **Database Preparation**

  - EF Core migrations applied (`dotnet ef database update`).
  - Verified in **Azure Portal → Query Editor**: tables `CatalogBrand`,`CatalogType`,`Orders`,`OrderItems` created.

- **Integration into eShopOnWeb**

  - Updated `appsettings.json` with SQL connection string:
    ```json
    "ConnectionStrings": {
      "CatalogConnection": "Server=tcp:<server>.database.windows.net,1433;Initial Catalog=eshopdb;User ID=<user>;Password=<pwd>;Encrypt=True;"
    }
    ```

- **Deployment**

  - eShopOnWeb Web App deployed to Azure App Service.
  - Connection string set in App Service → Configuration.

- **Testing**

  - Application started successfully with Azure SQL.
  - Placed test orders; verified rows appeared in `Orders` and `OrderItems`.

---


## 2. Task 2 — Delivery Service (Azure Function + Cosmos DB)

### Completed steps

- **Azure Infrastructure**

  - Cosmos DB account created (SQL API, serverless).
  - Database `delivery` and container `orders` created (partition key `/orderId`).
  - Storage account created for Function App.
  - Function App `func-delivery-orders` deployed.

- **Delivery Function**

  - New Function App project created (.NET 8 isolated worker).
  - HTTP-trigger `POST /api/orders` implemented.
  - Incoming JSON order requests are saved to Cosmos DB:
    ```json
    {
      "orderId": "42",
      "shippingAddress": {
        "name": "John Smith",
        "country": "US",
        "city": "New York",
        "zip": "10001",
        "line1": "5th Avenue 1"
      },
      "items": [
        { "productId": 4, "name": "Laptop", "qty": 1, "unitPrice": 1200 }
      ],
      "finalPrice": 1200
    }
    ```

- **Publishing and Testing**

  - Function published to Azure via `func azure functionapp publish`.
  - Verified locally with `curl` and deployed version with `Invoke-RestMethod`.
  - After request, new document appeared in Cosmos DB (Data Explorer).

---

## 3. Modify eShopOnWeb (Web App Service)

### Completed steps

- **Integration**

  - Added `DeliveryOrder` options class, `IDeliveryOrder` interface, and `DeliveryOrderService` (HttpClient).
  - Registered in DI (`Program.cs`):
    ```csharp
    builder.Services.Configure<DeliveryOrder>(builder.Configuration.GetSection("DeliveryOrder"));
    builder.Services.AddHttpClient<IDeliveryOrder, DeliveryOrderService>();
    ```
  - Updated `appsettings.json`:
    ```json
    "DeliveryOrder": {
      "FunctionUrl": "https://func-delivery-orders.azurewebsites.net/api/orders",
      "FunctionKey": "<function-key>"
    }
    ```
  - In `OrderService.CreateOrderAsync`, after saving the order:
    ```csharp
    await _delivery.SendAsync(order);
    ```

- **Deployment**

  - Web app deployed to Azure App Service.
  - App Settings updated with `DeliveryOrder__FunctionUrl` and `DeliveryOrder__FunctionKey`.

- **Testing**

  - Placed new order in eShopOnWeb.
  - Verified: document with shipping address, items, and final price appears in Cosmos DB.

---

## 4. Definition of Done ✅

### Task 1

- Web project **modified and deployed** to Azure App Service.
- Azure SQL Database **created and integrated**.
- Tables created and populated.
- Application works with Azure SQL Database.

### Task 2

- Web project **modified and deployed** to Azure App Service.
- Delivery Function **implemented and deployed**.
- Cosmos DB Database created.
- After order creation, a **record with shipping address, items, and final price** appears in Cosmos DB.

---

## Screenshots (see `/screenshots/` folder)

- `/Task-1/web-app-*.png` — Azure SQL database with tables.
- `/Task-2/az-func-delivery-*.png` — Delivery Function in Azure Portal.
- `/Task-2/cosmos-db-orders-*.png` — Cosmos DB container with saved orders.
- `/Task-2/web-eshop-*.png` — eShopOnWeb checkout confirmation.
