# =============================
# Step 0. Variables (adjust as needed)
# =============================
$RG = "rg-eshop-containers"
$LOC = "westeurope"
$ACR = "acreshop"
$PLAN = "plan-eshop-free"
$APIAPP = "app-eshop-api-xyz"
$WEBAPP = "app-eshop-web-xyz"
$IMAGE_API = "eshop-publicapi:latest"
$IMAGE_WEB = "eshop-web:latest"

# =============================
# Step 1. Register required providers
# =============================
az provider register -n Microsoft.ContainerRegistry --wait
az provider register -n Microsoft.Web --wait
az provider register -n Microsoft.Insights --wait
az provider register -n Microsoft.OperationalInsights --wait

# =============================
# Step 2. Create Resource Group and ACR
# =============================
az group create -n $RG -l $LOC | Out-Null
az acr create -g $RG -n $ACR --sku Basic --admin-enabled true
$ACR_LOGIN_SERVER = az acr show -n $ACR --query loginServer -o tsv

# =============================
# Step 3. Build and push images into ACR (from solution root)
# =============================
az acr build -r $ACR -t $IMAGE_API -f src/PublicApi/Dockerfile .
az acr build -r $ACR -t $IMAGE_WEB -f src/Web/Dockerfile .

# =============================
# Step 4. Create App Service Plan and Web Apps (Linux containers)
# =============================
az appservice plan create -g $RG -n $PLAN --sku F1 --is-linux

az webapp create -g $RG -p $PLAN -n $APIAPP --deployment-container-image-name mcr.microsoft.com/dotnet/aspnet:9.0
az webapp create -g $RG -p $PLAN -n $WEBAPP --deployment-container-image-name mcr.microsoft.com/dotnet/aspnet:9.0

# =============================
# Step 5. Link ACR images to Web Apps
# =============================
$ACR_USER = az acr credential show -n $ACR --query username -o tsv
$ACR_PASS = az acr credential show -n $ACR --query passwords[0].value -o tsv

# API → API image
az webapp config container set -g $RG -n $APIAPP `
  --docker-custom-image-name "$ACR_LOGIN_SERVER/$IMAGE_API" `
  --docker-registry-server-url "https://$ACR_LOGIN_SERVER" `
  --docker-registry-server-user $ACR_USER `
  --docker-registry-server-password $ACR_PASS | Out-Null

# WEB → Web image
az webapp config container set -g $RG -n $WEBAPP `
  --docker-custom-image-name "$ACR_LOGIN_SERVER/$IMAGE_WEB" `
  --docker-registry-server-url "https://$ACR_LOGIN_SERVER" `
  --docker-registry-server-user $ACR_USER `
  --docker-registry-server-password $ACR_PASS | Out-Null

# =============================
# Step 6. Configure App Settings
# =============================
$API_URL = "https://$APIAPP.azurewebsites.net"
$API_BASE = "$API_URL/api/"

# API: port + InMemory DB
az webapp config appsettings set -g $RG -n $APIAPP --settings `
  WEBSITES_PORT=8080 `
  UseOnlyInMemoryDatabase=true | Out-Null

# WEB: port + InMemory + CatalogBaseUrl + Blazor Admin apiBase
az webapp config appsettings set -g $RG -n $WEBAPP --settings `
  WEBSITES_PORT=8080 `
  UseOnlyInMemoryDatabase=true `
  baseUrls__apiBase=$API_BASE | Out-Null

# Restart both apps
az webapp restart -g $RG -n $APIAPP | Out-Null
az webapp restart -g $RG -n $WEBAPP | Out-Null

# =============================
# Step 7. Enable Continuous Deployment from ACR
# =============================
az webapp deployment container config -g $RG -n $APIAPP --enable-cd true | Out-Null
az webapp deployment container config -g $RG -n $WEBAPP --enable-cd true | Out-Null

# =============================
# Step 8. Enable and view logs
# =============================
az webapp log config -g $RG -n $APIAPP --docker-container-logging filesystem | Out-Null
az webapp log config -g $RG -n $WEBAPP --docker-container-logging filesystem | Out-Null

# Tail logs (API); uncomment for WEB as needed
# az webapp log tail -g $RG -n $APIAPP
# az webapp log tail -g $RG -n $WEBAPP
