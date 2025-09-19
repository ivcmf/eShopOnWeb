# ============================================================================
# eShopOnWeb — Final Azure Environment Bootstrap (PowerShell + Azure CLI)
# - Web App with autoscale and deployment slot
# - Public API in Container (ACR)
# - Service Bus (orderreserve + ordercreated)
# - Storage (Blob container 'orders')
# - Function Apps: OrderItemsReserver, DeliveryOrderProcessor
# - Cosmos DB (Delivery/Orders)
# - Traffic Manager profile
# NOTE: You must be logged in:  az login  (and pick the right subscription)
# ============================================================================

# ---------------------------
# 0. Variables (adjust names)
# ---------------------------
$SUFFIX = (Get-Random)                                # keep names globally unique
$RG = "rg-eshop-final"
$LOC = "westeurope"                                # was 'centralus' → use your region
$PLAN = "plan-eshop-final"
$WEBAPP = "app-eshop-web-$SUFFIX"
$APIAPP = "app-eshop-api-$SUFFIX"
$ACR = "acreshop$SUFFIX"
$ST = "steshop$SUFFIX"
$SBNS = "sb-eshop-$SUFFIX"
$SBQ = "orderreserve"                              # queue for reservation
$SBQPROC = "ordercreated"                              # queue for delivery processor / optional
$FUNCRES = "func-orderitems-reserver-$SUFFIX"
$FUNCPROC = "func-delivery-processor-$SUFFIX"
$COSMOS = "cosmos-eshop-$SUFFIX"
$SQLSERVER = "sql-eshop-$SUFFIX"
$SQLDB1 = "CatalogDB"
$SQLDB2 = "Identity"
$AI = "ai-eshop-$SUFFIX"

# ---------------------------
# 1. Resource Group
# ---------------------------
az group create -n $RG -l $LOC

# ---------------------------
# 2. Application Insights (optional but handy)
# ---------------------------
az monitor app-insights component create -g $RG -l $LOC -a $AI | Out-Null

# ---------------------------
# 3. App Service Plan (Linux) + Autoscale rules
# ---------------------------
az appservice plan create -g $RG -n $PLAN --sku B1 --is-linux

# Autoscale: min=1, max=3, default=1; scale out if CPU > 70% (5m), in if < 30% (10m)
az monitor autoscale create -g $RG --resource $PLAN `
    --resource-type Microsoft.Web/serverfarms `
    --name autoscale-eshop --min-count 1 --max-count 3 --count 1

az monitor autoscale rule create -g $RG --autoscale-name autoscale-eshop `
    --condition "Percentage CPU > 70 avg 5m" --scale out 1

az monitor autoscale rule create -g $RG --autoscale-name autoscale-eshop `
    --condition "Percentage CPU < 30 avg 10m" --scale in 1

# ---------------------------
# 4. Storage (for Blob & Functions)
# ---------------------------
az storage account create -g $RG -n $ST -l $LOC --sku Standard_LRS
az storage container create --account-name $ST -n orders --auth-mode login | Out-Null
$ST_CONN = az storage account show-connection-string -g $RG -n $ST --query connectionString -o tsv

# ---------------------------
# 5. SQL Server + DBs
# ---------------------------
az sql server create -g $RG -n $SQLSERVER -l $LOC -u sqladmin -p "MyP@ssw0rd!"
az sql server firewall-rule create -g $RG -s $SQLSERVER -n AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
az sql db create -g $RG -s $SQLSERVER -n $SQLDB1 --service-objective S0
az sql db create -g $RG -s $SQLSERVER -n $SQLDB2 --service-objective S0

# ---------------------------
# 6. Cosmos DB (Delivery/Orders)
# ---------------------------
az provider register --namespace Microsoft.DocumentDB | Out-Null
az cosmosdb create -g $RG -n $COSMOS --kind GlobalDocumentDB | Out-Null
az cosmosdb sql database create -g $RG -a $COSMOS -n Delivery | Out-Null
az cosmosdb sql container create -g $RG -a $COSMOS -d Delivery -n Orders -p "/orderId" | Out-Null

# Connection string (primary read-write)
$COSMOS_CONN = az cosmosdb keys list -g $RG -n $COSMOS --type connection-strings --query "connectionStrings[0].connectionString" -o tsv

# ---------------------------
# 7. Service Bus (namespace + queues)
# ---------------------------
az servicebus namespace create -g $RG -n $SBNS -l $LOC --sku Standard
az servicebus queue create -g $RG --namespace-name $SBNS -n $SBQ --max-delivery-count 3 --enable-dead-lettering-on-message-expiration true
# optional second queue for delivery processor / demo pipeline
az servicebus queue create -g $RG --namespace-name $SBNS -n $SBQPROC --max-delivery-count 10 --enable-dead-lettering-on-message-expiration true

$SB_CONN = az servicebus namespace authorization-rule keys list -g $RG `
    --namespace-name $SBNS --name RootManageSharedAccessKey `
    --query primaryConnectionString -o tsv

# ---------------------------
# 8. Function Apps (dotnet isolated)
# ---------------------------
az functionapp create -g $RG -n $FUNCRES -s $ST -c $LOC --consumption-plan-location $LOC --runtime dotnet-isolated --functions-version 4
az functionapp create -g $RG -n $FUNCPROC -s $ST -c $LOC --consumption-plan-location $LOC --runtime dotnet-isolated --functions-version 4

# App settings for functions
az functionapp config appsettings set -g $RG -n $FUNCRES --settings `
    "ServiceBus__Connection=$SB_CONN" `
    "Blob__Connection=$ST_CONN" `
    "Blob__Container=orders" `
    "APPINSIGHTS_INSTRUMENTATIONKEY=$(az monitor app-insights component show -g $RG -a $AI --query instrumentationKey -o tsv)"

az functionapp config appsettings set -g $RG -n $FUNCPROC --settings `
    "ServiceBus__Connection=$SB_CONN" `
    "Cosmos__Connection=$COSMOS_CONN" `
    "APPINSIGHTS_INSTRUMENTATIONKEY=$(az monitor app-insights component show -g $RG -a $AI --query instrumentationKey -o tsv)"

# ---------------------------
# 9. Web App (Production + Staging slot)
# ---------------------------
az webapp create -g $RG -p $PLAN -n $WEBAPP --runtime "DOTNETCORE:9.0"

# Link App Insights
az webapp config appsettings set -g $RG -n $WEBAPP --settings `
    "APPINSIGHTS_INSTRUMENTATIONKEY=$(az monitor app-insights component show -g $RG -a $AI --query instrumentationKey -o tsv)"

# Deployment slot: staging
az webapp deployment slot create -g $RG -n $WEBAPP --slot staging
# Keep slot-specific settings (example)
az webapp config appsettings set -g $RG -n $WEBAPP --slot staging --settings "SLOT_SETTING_SAMPLE=staging" --slot-settings "SLOT_SETTING_SAMPLE"

# ---------------------------
# 10. Public API (Container via ACR) + wire to Web App for container registry
# ---------------------------
az acr create -g $RG -n $ACR --sku Basic --admin-enabled true
$ACR_LOGIN_SERVER = az acr show -n $ACR --query loginServer -o tsv
$ACR_USER = az acr credential show -n $ACR --query username -o tsv
$ACR_PASS = az acr credential show -n $ACR --query passwords[0].value -o tsv

# Example build (expects Dockerfile at src/PublicApi/Dockerfile). Adjust path if needed.
# az acr build -g $RG -r $ACR -t eshopapi:latest -f src/PublicApi/Dockerfile .

# Create API app pinned to container image (push image beforehand or set later)
az webapp create -g $RG -p $PLAN -n $APIAPP -i "$ACR_LOGIN_SERVER/eshopapi:latest"

# Grant Web App access to pull from ACR
az webapp config container set -g $RG -n $APIAPP `
    --docker-custom-image-name "$ACR_LOGIN_SERVER/eshopapi:latest" `
    --docker-registry-server-url "https://$ACR_LOGIN_SERVER" `
    --docker-registry-server-user $ACR_USER `
    --docker-registry-server-password $ACR_PASS

# ---------------------------
# 11. Traffic Manager (profile + endpoint for Web)
# ---------------------------
az network traffic-manager profile create -g $RG -n eshop-tm --routing-method Performance --unique-dns-name "eshopfinal-$SUFFIX"
$WEB_ID = az webapp show -g $RG -n $WEBAPP --query id -o tsv
az network traffic-manager endpoint create -g $RG --profile-name eshop-tm -n webendpoint --type azureEndpoints --target-resource-id $WEB_ID
# You can add API endpoint similarly if desired
# $API_ID = az webapp show -g $RG -n $APIAPP --query id -o tsv
# az network traffic-manager endpoint create -g $RG --profile-name eshop-tm -n apiendpoint --type azureEndpoints --target-resource-id $API_ID

# ---------------------------
# 12. Useful outputs
# ---------------------------
Write-Host "\n=== OUTPUTS ===" -ForegroundColor Cyan
Write-Host "Resource Group: $RG"
Write-Host "Web (prod): https://$WEBAPP.azurewebsites.net"
Write-Host "Web (staging slot): https://$WEBAPP-staging.azurewebsites.net"
Write-Host "API (container): https://$APIAPP.azurewebsites.net"
Write-Host "Traffic Manager DNS: $(az network traffic-manager profile show -g $RG -n eshop-tm --query dnsConfig.fqdn -o tsv)"
Write-Host "Storage Conn: $ST_CONN"
Write-Host "Service Bus Conn: $SB_CONN"
Write-Host "Cosmos Conn: $COSMOS_CONN"

# Tail (optional)
# az webapp log tail -g $RG -n $APIAPP
# az webapp log tail -g $RG -n $WEBAPP
