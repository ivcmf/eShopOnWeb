# Monitoring and Logging — Report

## 1. Add Application Insights Logging and Check Metrics

### Steps Performed

**Added Application Insights**
- In `Program.cs`:
```csharp
builder.Services.AddApplicationInsightsTelemetry();
```

**Logging in CatalogItemListPagedEndpoint**
```csharp
    Logger.LogInformation(
    "Returned {Count} catalog items from database (totalItems={Total}, pageIndex={PageIndex}, pageSize={PageSize})",
    items.Count, totalItems, request.PageIndex, request.PageSize);
```

**Deploy and Check Logs**
- Checked logs in Application Insights.
- Kusto query:
```kusto
traces
| where timestamp > ago(1h)
| where message contains "Returned"
```

**Check CPU and Request Metrics**
- App Service → Metrics → CPU Usage and Requests.

**Artificial Error Creation**
```csharp
throw new Exception("Cannot move further");
```

**Kusto Query for Errors**
```kusto
exceptions
| where timestamp > ago(1h)
| where outerMessage contains "Cannot move further"
```

**Check in Failures**
- Errors found, stack trace inspected.

✅ *Definition of done*:  
- Info logs visible in AI.  
- Errors detected via Failures/Kusto.  
- Metrics updated.

---

## 2. Investigate the application crashing during the start

**Steps Performed**
- In `Program.cs` before `app.Run()`:
```csharp
throw new Exception("Cannot move further");
```
- Application crashed at startup.
- In AI → Failures, error located.

✅ *Definition of done*: error visible in Azure with file reference.

---

## 📂 Screenshots
Screenshots are stored in [`screenshots/`]:
- `ai-info-logs.png` — logs with item count.
- `ai-error-logs.png` — errors in AI.
- `ai-failures.png` — error 500 card.
- `ai-metrics.png` — CPU and request charts.
- `app-crashed-log-stream.png` — app crashed at startup.
