terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # Remote backend configuration for state storage
  backend "azurerm" {
    resource_group_name  = "rg-rentlanka-prod"
    storage_account_name = "sarentlankatfstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# 1. Resource Group
resource "azurerm_resource_group" "prod" {
  name     = "rg-rentlanka-prod"
  location = "southeastasia" # Latency friendly region for Sri Lanka / South Asia
  tags = {
    Environment = "Production"
    Project     = "RentLanka"
    ManagedBy   = "Terraform"
  }
}

# 2. Log Analytics Workspace (for Application Insights)
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "log-rentlanka-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = azurerm_resource_group.prod.tags
}

# 3. Application Insights
resource "azurerm_application_insights" "app_insights" {
  name                = "appi-rentlanka-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.workspace.id
  tags                = azurerm_resource_group.prod.tags
}

# 4. App Service Plan (Linux B1 tier for cost savings)
resource "azurerm_service_plan" "asp" {
  name                = "asp-rentlanka-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = azurerm_resource_group.prod.tags
}

# 5. Linux Web App (Backend API)
resource "azurerm_linux_web_app" "api" {
  name                = "rentlanka-api"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    always_on        = true
    ftps_state       = "Disabled"
    
    application_stack {
      dotnet_version = "8.0" # or "9.0" as target runtime stack on Azure App Service
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT"                  = "Production"
    "APPINSIGHTS_INSTRUMENTATIONKEY"          = azurerm_application_insights.app_insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"   = azurerm_application_insights.app_insights.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }

  tags = azurerm_resource_group.prod.tags
}

# 6. Azure Key Vault
resource "azurerm_key_vault" "vault" {
  name                        = "kv-rentlanka"
  location                    = azurerm_resource_group.prod.location
  resource_group_name         = azurerm_resource_group.prod.name
  tenant_id                   = "546a340a-e14f-4700-9f55-5d87b1fb31c9" # User's Azure Active Directory Tenant ID
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  access_policy {
    tenant_id = azurerm_linux_web_app.api.identity[0].tenant_id
    object_id = azurerm_linux_web_app.api.identity[0].principal_id

    secret_permissions = [
      "Get",
      "List"
    ]
  }

  tags = azurerm_resource_group.prod.tags
}

# 7. Azure Static Web App (Frontend client hosting)
resource "azurerm_static_site" "web" {
  name                = "swa-rentlanka-prod"
  location            = "eastasia" # SWA available region near Sri Lanka
  resource_group_name = azurerm_resource_group.prod.name
  sku_tier            = "Free"
  sku_size            = "Free"
  tags                = azurerm_resource_group.prod.tags
}
