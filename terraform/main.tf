resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

## Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "acrstockdataproject"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false  # Disabled for security
}

## Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-stock-data-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aksstockdata"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"  # As per your requirement
  }

  identity {
    type = "SystemAssigned"
  }
}

## Azure Event Hubs Namespace and Event Hub
resource "azurerm_eventhub_namespace" "eh_namespace" {
  name                = "eh-namespace-stock-data"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
}

resource "azurerm_eventhub" "eventhub" {
  name                = "eh-stock-data"
  namespace_name      = azurerm_eventhub_namespace.eh_namespace.name
  resource_group_name = azurerm_resource_group.rg.name
  partition_count     = 1  # Reduced from 2 to 1
  message_retention   = 1
}

## Azure Databricks Workspace
resource "azurerm_databricks_workspace" "databricks_ws" {
  name                          = "dbw-stock-data"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  sku                           = "standard"
  public_network_access_enabled = true  # Avoids unnecessary network resources
}

## Azure Storage Account and Container
resource "azurerm_storage_account" "storage_account" {
  name                     = "ststockdataproject"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true  # Set to false if Data Lake Gen2 features are not needed
}

resource "azurerm_storage_container" "storage_container" {
  name                  = "processed-data"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}
