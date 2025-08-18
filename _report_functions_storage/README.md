# Report: Functions and Storage

## 1. Add new service OrderItemsReserver (Azure Function)

### Completed steps

- **Azure Infrastructure**
  - Resource group `rg-func-demo` created.
  - Storage account `stfunceshop1121267681` created with container `orders`.
  - Function App `func-eshop-reserver` deployed.

- **OrderItemsReserver Function (see `/OrderItemsReserver/` folder)**
  - New Function App project `OrderItemsReserver` created.
  - HTTP-trigger `POST /api/reserve` implemented.
  - Incoming JSON order requests are saved to the `orders` blob container:
    ```json
    {"orderId":"1","items":[{"itemId":"4","quantity":1},{"itemId":"5","quantity":1},{"itemId":"3","quantity":1}]}
    ```
  - JSON files are stored as `<orderId>-<timestamp>.json`.
  - Logging added via `ILogger`.

- **Publishing and Testing**
  - Function published to Azure via `func azure functionapp publish`.
  - Verified locally using `curl` and in Azure Portal.
  - After requests, JSON files appeared in Blob Storage.

---

## 2. Modify eShopOnWeb (Web App Service)

### Completed steps

- **Integration**
  - In `OrderService.CreateOrderAsync`, after saving the order, `OrderReserveClient` is invoked.
  - `OrderReserveClient` sends POST request to the `OrderItemsReserver` function with `orderId` and order items.
  - Web configuration (`appsettings.json`) updated:
    ```json
    "OrderReserve": {
      "FunctionUrl": "https://func-eshop-reserver.azurewebsites.net/api/reserve",
      "FunctionKey": "<function-key>"
    }
    ```

- **Deployment**
  - Web app deployed to Azure App Service.
  - App Settings updated with `OrderReserve__FunctionUrl` and `OrderReserve__FunctionKey`.

- **Testing**
  - Checkout flow tested in the Web app.
  - After successful order, a JSON file with order details appeared in Blob Storage.

---

## 3. Definition of Done ✅

- Web project **modified and deployed** to Azure App Service.  
- OrderItemsReserver function **implemented and deployed** to Azure Function App.  
- After order creation, a **JSON file with order details** appears in Blob Storage.  

---

## Screenshots (see `/screenshots/` folder)

- `az-function-app-*.png` — Function App in Azure Portal.  
- `stfunceshop-blob-storage-*.png` — Orders container in Blob Storage with JSON files.  
- `web-app-*.png` — Web application order success page.  

