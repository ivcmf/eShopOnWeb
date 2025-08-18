# Variables
$RG = "rg-func-demo"
$LOC = "westeurope"
$ST = "stfunceshop$(Get-Random)"        # must be unique in Azure
$PLAN = "plan-func-eshop"
$FUNC = "func-eshop-reserver"
$CONTAINER = "orders"

# Resource Group and Storage
az group create -n $RG -l $LOC
az storage account create -g $RG -n $ST -l $LOC --sku Standard_LRS --kind StorageV2
az storage container create --name $CONTAINER --account-name $ST --auth-mode login

# Set minimum TLS to 1.2 for storage
az storage account update -g $RG -n $ST --min-tls-version TLS1_2

# Consumption plan (Linux) and Function App (.NET Isolated)
#az functionapp plan create -g $RG -n $PLAN --location $LOC --min-instances 0 --sku Y1 --is-linux

# Create Function App on Consumption (Linux, .NET Isolated v4)
az functionapp create `
  --resource-group $RG `
  --name $FUNC `
  --storage-account $ST `
  --consumption-plan-location $LOC `
  --os-type Linux `
  --functions-version 4 `
  --runtime dotnet-isolated

# (Optional) configure CORS for calls from Web App
# az functionapp cors add -g $RG -n $FUNC --allowed-origins https://<your-webapp>.azurewebsites.net

az webapp config appsettings set -g rg-eshop-neu -n app-web-rai2usfnzmkvo `
  --settings "OrderReserve__FunctionUrl=https://func-eshop-reserver.azurewebsites.net/api/reserve" `
  "OrderReserve__FunctionKey=<function-key>"
