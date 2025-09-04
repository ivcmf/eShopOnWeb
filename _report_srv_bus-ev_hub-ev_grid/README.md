# Report: Azure Service Bus → Blob Storage with Logic App Fallback for eShopOnWeb

## 1. Goal

The goal of this task was to implement an integration between the **eShopOnWeb** application and a new service called **OrderItemsReserver** (Azure Function). After a customer successfully creates an order, the service must:

- Generate a JSON file with order details (`itemId`, `quantity`).
- Upload the JSON file to **Azure Blob Storage**.
- Use **Azure Service Bus Queue** as the communication channel between eShopOnWeb and the function.
- Implement a **retry policy** for uploading to Blob (up to 3 attempts).
- Provide a **fallback scenario**: if file creation fails (e.g., invalid Blob connection string, service unavailable), an email notification with order details must be sent via **Logic App**.

---

## 2. Deployed Components

- **Resource Group:** `rg-eshop-bus`
- **Service Bus Namespace & Queue:** `sb-eshop-<random>` / `orderreserve`
- **Storage Account:** `stesorder<random>` with container `orders`
- **Function App:** `func-orderitems-reserver` (isolated .NET worker)
- **Logic App:** `logic-app-eshop` (fallback email sender)

*(see screenshot ******`resources-overview.png`******)*

---

## 3. Service Bus Configuration

- Created **Service Bus Namespace** with SKU **Standard**.
- Created Queue `orderreserve` with **MaxDeliveryCount = 3** and **DLQ enabled**.
- Retrieved Service Bus connection string and stored in Function App settings.

*(see screenshot ******`servicebus-queue*.png`******)*

---

## 4. Blob Storage Configuration

- Created storage account.
- Added container `orders` for JSON files.
- Connection string stored in Function App settings.

*(see screenshot ******`storage-container.png`******)*

---

## 5. Function App (OrderItemsReserver)

- Implemented **ServiceBusTrigger** function that:
  - Receives messages from `orderreserve` queue.
  - Uploads the message body as a JSON file into Blob Storage.
  - Uses retry policy (3 attempts, exponential backoff).
  - Throws exception on failure to trigger fallback.

*(see screenshot ******`function-app*.png`******)*

---

## 6. Logic App Fallback

- Logic App (Consumption plan) created.
- Trigger: **When one or more messages arrive in a Service Bus queue (DLQ)**.
- Action: **Parse JSON** → **Send email (Office 365)**.
- Sends order details JSON as email body.

*(see screenshot ******`logicapp-flow.png`******)*

---

## 7. eShopOnWeb Integration

- Added **OrderItemsReserverClient** to send order messages to Service Bus.
- Modified **OrderService.CreateOrderAsync** to call `_orderItemsReserver.SendAsync(order, cancellationToken)` after order persistence.
- Configured Service Bus connection string in App Service settings.

*(see screenshot ******`eshop-servicebus-config.png`******)*

---

## 8. Testing

- **Positive case**: order placed successfully → JSON file appears in `orders` container.
- **Negative case**: invalid Blob connection string → Function fails → message moves to DLQ → Logic App triggered → email with order details received.

*(see screenshot ******`blob-file-success.png`******, ******`email-fallback.png`******)*

---

## 9. Definition of Done ✅

- eShopOnWeb web app modified and deployed to App Service.
- OrderItemsReserver Function implemented and deployed.
- Service Bus namespace and queue created and configured.
- Blob Storage configured for JSON order uploads.
- Retry policy and DLQ fallback implemented.
- Logic App created to send email notifications when fallback occurs.
- End-to-end tests passed (both success and failure scenarios).

---

## 10. Screenshots

- `resources-overview.png` — Deployed Azure resources overview.
- `servicebus-queue*.png` — Service Bus Queue configuration.
- `storage-container.png` — Orders Blob container.
- `function-app*.png` — Function App code snippet.
- `logicapp-flow*.png` — Logic App workflow.
- `eshop-servicebus-config.png` — eShopOnWeb Service Bus configuration.
- `blob-file-success.png` — Successful JSON upload to Blob.
- `email-fallback.png` — Email received from Logic App fallback.
