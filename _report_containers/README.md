# Report: ACR → App Service Deployment for eShopOnWeb

## 1. Goal

Deploy **eShopOnWeb** into Azure using container images stored in **Azure Container Registry (ACR)**, with two separate apps: **PublicApi** and **Web**, hosted in **App Service (Linux)**. Ensure continuous deployment (CD) from ACR, fix Blazor Admin configuration, and verify functionality.

---

## 2. Deployed Components

- **Resource Group:** `rg-eshop-containers`
- **Azure Container Registry (ACR):** `acreshop`
- **App Service Plan:** `plan-eshop-free` (Linux, F1)
- **Web Apps:** `app-eshop-api-xyz`, `app-eshop-web-xyz`
- **Container Images:** `eshop-publicapi:latest`, `eshop-web:latest`

*(see screenshot ******`resources-overview.png`******)*

---

## 3. Container Image Build

- Built and pushed container images into ACR using **az acr build**:
  - PublicApi → `src/PublicApi/Dockerfile`
  - Web → `src/Web/Dockerfile`

*(see screenshot ******`acr-build.png`******)*

---

## 4. App Service Configuration

- Created Linux App Service Plan (F1).
- Created two Web Apps linked to ACR images.
- Configured environment variables:
  - `WEBSITES_PORT=8080`
  - `UseOnlyInMemoryDatabase=true`
  - `baseUrls__apiBase=https://<APIAPP>.azurewebsites.net/api/`

*(see screenshot ******`app-eshop-*.png`******)*

---

## 5. Continuous Deployment

- Enabled **Container Continuous Deployment (CD)** for both APIAPP and WEBAPP.
- Verified that pushing a new image with the same tag redeploys apps automatically.

*(see screenshot ******`cd-enabled-*.png`******)*

---

## 6. Logging and Monitoring

- Enabled container logging to filesystem.
- Verified logs via `az webapp log tail`.

*(see screenshot ******`logs.png`******)*

---

## 7. Testing

- **Positive case:** Web and API endpoints responsive; Blazor Admin connects correctly.

*(see screenshot ******`wep-app-success.png`******)*

---

## 8. Definition of Done ✅

- eShopOnWeb Web and API apps created and deployed to App Service.
- Containers built and stored in ACR.
- ACR images linked to respective Web Apps.
- App Settings configured, including Blazor Admin API base URL.
- Continuous Deployment enabled.
- Logging and monitoring validated.
- Admin panel verified to connect to API without errors.

---

## 9. Screenshots

- `resources-overview.png` — Deployed Azure resources overview
- `acr-build.png` — ACR build and pushed images
- `app-eshop-*.png` — App Settings configuration
- `cd-enabled-*.png` — Continuous Deployment enabled
- `logs-*.png` — Log streaming output
- `wep-app-success.png` — Blazor Admin working with API

---

## 10. Conclusion

The deployment of **eShopOnWeb** to Azure via **ACR → App Service** was successful. Both Web and API applications are running with continuous deployment enabled, Blazor Admin configuration fixed, and logging/monitoring set up.
