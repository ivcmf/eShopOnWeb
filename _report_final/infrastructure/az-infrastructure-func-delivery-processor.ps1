# Variables
$RG = "rg-eshop"
$LOC = "centralus"
$PLAN = "plan-eshop-linux"
$ST = "stfunc$(Get-Random)"
$FUNC = "func-delivery-orders"
$COSMOS = "cosmos-eshop-$(Get-Random)"

# Create Resource Group
az group create -n $RG -l $LOC

# App Service Plan (Linux) — (mainly for web apps, optional for Task 2)
az appservice plan create -g $RG -n $PLAN --sku B1 --is-linux

# Cosmos DB (Serverless NoSQL)
az cosmosdb create `
    --name $COSMOS `
    --resource-group $RG `
    --locations regionName=$LOC `
    --kind GlobalDocumentDB `
    --capabilities EnableServerless

# Cosmos database
az cosmosdb sql database create -g $RG -a $COSMOS -n delivery

# Cosmos container
az cosmosdb sql container create -g $RG -a $COSMOS -d delivery -n orders `
    --partition-key-path "/orderId"

# Retrieve Cosmos connection string
$COSMOS_CONN = az cosmosdb keys list -g $RG -n $COSMOS `
    --type connection-strings `
    --query "connectionStrings[0].connectionString" -o tsv

Write-Host "Cosmos Connection String:" $COSMOS_CONN

# Storage Account for Azure Functions
az storage account create -g $RG -n $ST -l $LOC --sku Standard_LRS

# Function App (Consumption, Linux, .NET Isolated)
az functionapp create -g $RG -n $FUNC -s $ST -c $LOC `
    --consumption-plan-location $LOC --runtime dotnet-isolated --functions-version 4

# Configure App Settings for Cosmos
az functionapp config appsettings set -g $RG -n $FUNC --settings `
    "Cosmos__ConnectionString=$COSMOS_CONN" `
    "Cosmos__Database=delivery" `
    "Cosmos__Container=orders"

# Invoke url: https://func-delivery-processor.azurewebsites.net/api/orders
# x-functions-key: 
