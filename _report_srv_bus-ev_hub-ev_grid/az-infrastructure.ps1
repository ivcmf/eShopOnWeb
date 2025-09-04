# Variables
$RG = "rg-eshop-bus"
$LOC = "westeurope"
$SBNS = "sb-eshop-$(Get-Random)"
$SBQ = "orderreserve"
$ST = "stesorder$(Get-Random)"
$FUNC = "func-orderitems-reserver"
$CONTAINER = "orders"

# Resource Group
az group create -n $RG -l $LOC

# Storage (for Blob and for FunctionApp)
az storage account create -g $RG -n $ST -l $LOC --sku Standard_LRS --kind StorageV2
az storage container create --name $CONTAINER --account-name $ST --auth-mode login

# Set minimum TLS to 1.2 for storage
az storage account update -g $RG -n $ST --min-tls-version TLS1_2

# Service Bus (лучше SKU Standard, чтобы было DLQ/расширения)
az servicebus namespace create -g $RG -n $SBNS -l $LOC --sku Standard
az servicebus queue create -g $RG --namespace-name $SBNS -n $SBQ --max-delivery-count 3 `
  --enable-dead-lettering-on-message-expiration true

# Consumption plan (Linux) and Function App (.NET Isolated)
# Create Function App on Consumption (Linux, .NET Isolated v4)
az functionapp create `
  --resource-group $RG `
  --name $FUNC `
  --storage-account $ST `
  --consumption-plan-location $LOC `
  --os-type Linux `
  --functions-version 4 `
  --runtime dotnet-isolated

# Prepare connection strings
$SB_CONN = az servicebus namespace authorization-rule keys list -g $RG `
  --namespace-name $SBNS --name RootManageSharedAccessKey `
  --query primaryConnectionString -o tsv

# Settings for Function App
az functionapp config appsettings set -g $RG -n $FUNC --settings `
  "ServiceBusConnection=$SB_CONN" `
  "BlobConnection=$ST_CONN" `
  "BlobContainer=orders" `
  "FallbackLogicAppUrl="

# Logic App (Consumption)
az logicapp create -g $RG -n logicapp-fallback -l $LOC --sku Consumption
