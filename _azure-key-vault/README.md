# Report: Azure Key Vault Integration for eShopOnWeb

## 1. Goal

The goal of this task was to store the Azure SQL connection strings in **Azure Key Vault** and configure the **App Service** to securely retrieve them using **Managed Identity** and **Key Vault References** without code changes.

---

## 2. Deployed Components

* **Resource Group:** `rg-eshop-db`
* **App Service:** `app-web-cngnyib47vm5e`
* **App Service Plan:** `plan-cngnyib47vm5e`
* **SQL Servers:**

  * `sql-catalog-cngnyib47vm5e` with database `catalogDatabase`
  * `sql-identity-cngnyib47vm5e` with database `identityDatabase`
* **Key Vault:** `kv-cngnyib47vm5e`

*(see screenshot ******`eshop-resources.png`******)*

---

## 3. Key Vault Configuration

* Created Key Vault `kv-cngnyib47vm5e`.
* Added the following secrets:

  * `AZURE-SQL-CATALOG-CONNECTION-STRING`
  * `AZURE-SQL-IDENTITY-CONNECTION-STRING`


*(see screenshot ******`eshop-kv-secrets.png`******)*

---

## 4. Managed Identity for App Service

* **System Assigned Managed Identity** was enabled for the App Service.
* Principal ID: `27731c03-ee1f-4947-a0bc-7547f3b9c309`
* Status: **On**

*(see screenshot ******`eshop-app-service-identity.png`******)*

---

## 5. Access Policies

* Configured Access Policy in Key Vault for `app-web-cngnyib47vm5e`.
* Granted **Get** and **List** permissions for secrets.

*(see screenshot ******`eshop-kv-access-policies.png`******)*

---

## 6. App Service Configuration

* In **Environment Variables**, configured Key Vault references:

  * `AZURE_SQL_CATALOG_CONNECTION_STRING_KEY = @Microsoft.KeyVault(SecretUri=...)`
  * `AZURE_SQL_IDENTITY_CONNECTION_STRING_KEY = @Microsoft.KeyVault(SecretUri=...)`
  * `AZURE_KEY_VAULT_ENDPOINT`


*(see screenshot ******`eshop-app-service-envvars.png`******)*

---

## 7. Testing

* Restarted App Service.
* eShopOnWeb application loaded successfully.
* Placed an order to confirm database connectivity.
* The app was able to access the SQL databases using the connection strings stored in Key Vault.

*(screenshot of successful checkout attached: ******`eshop-ui-checkout.png`******)*

---

## 8. Definition of Done ✅

* Key Vault created and secrets added.
* Managed Identity enabled for App Service.
* Access Policy configured (Get, List for secrets).
* App Settings reference Key Vault Secrets via `@Microsoft.KeyVault`.
* Application successfully works using secrets from Key Vault.

## 9. Screenshots (./screenshots/)

* `eshop-resources.png` — Deployed Azure resources overview.
* `eshop-kv-secrets.png` — Secrets stored in Key Vault.
* `eshop-app-service-identity.png` — Managed Identity enabled for App Service.
* `eshop-kv-access-policies.png` — Access Policies configuration.
* `eshop-app-service-envvars.png` — Environment variables with Key Vault references.
* `eshop-ui-checkout.png` — Successful eShopOnWeb checkout (application running with Key Vault secrets).
