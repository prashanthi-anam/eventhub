data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "example" {
}

resource "azurerm_role_assignment" "Reader" {
  scope                = azurerm_eventhub.testeventhub.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_client_config.example.object_id
}


locals {
  resource_group = "rg-1"
  location       = "eastus"
}

resource "azurerm_resource_group" "app_grp" {
    name = "rg-1"
    location = "eastus"
    
  
}

resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = local.resource_group
  address_space       = ["10.0.0.0/16"]
  depends_on = [ azurerm_resource_group.app_grp ]
}

resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.1.0/24"]
  depends_on = [
    azurerm_virtual_network.app_network
  ]
}

resource "azurerm_public_ip" "app_public_ip" {
  name                = "app-public-ip"
  resource_group_name = local.resource_group
  location            = local.location
  allocation_method   = "Static"
  depends_on = [ azurerm_resource_group.app_grp ]
}
resource "azurerm_network_interface" "app_interface" {
  name                = "app-interface"
  location            = local.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app_public_ip.id
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_public_ip.app_public_ip,
    azurerm_subnet.SubnetA
  ]
}
resource "azurerm_storage_account" "appstore" {
  name                     = "appstore457768714567"
  resource_group_name      = local.resource_group
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on = [ azurerm_resource_group.app_grp ]


}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = "appstore457768714567"
  container_access_type = "blob"
  depends_on = [
    azurerm_storage_account.appstore
  ]
}



resource "azurerm_eventhub_namespace" "testeventhubnamespace" {
  name                = "testeventhub1220301902"
  location            = local.location
  resource_group_name = local.resource_group
  sku                 = "Standard"
  depends_on = [ azurerm_resource_group.app_grp ]
}
resource "azurerm_eventhub" "testeventhub" {
  name                = "test-eventhub"
  namespace_name      = azurerm_eventhub_namespace.testeventhubnamespace.name
  resource_group_name = local.resource_group
  partition_count     = 4
  message_retention   = 1


  capture_description {
    enabled             = true
    encoding            = "Avro"
    interval_in_seconds = 300
    size_limit_in_bytes = 10485763

    destination {
      name = "EventHubArchive.AzureBlockBlob"

      archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}-{Month}-{Day}T{Hour}:{Minute}:{Second}"
      blob_container_name = "data"
      storage_account_id  = azurerm_storage_account.appstore.id
    }
  }
 depends_on = [ azurerm_resource_group.app_grp ]
}

resource "azurerm_private_endpoint" "privateendpoint1" {
  name                = "eventhub-private-endpoint-1"
  location            = local.location
  resource_group_name = local.resource_group
  subnet_id           = azurerm_subnet.SubnetA.id

  private_service_connection {
    name                           = "example-eventhub-private-connection"
    private_connection_resource_id = azurerm_eventhub_namespace.testeventhubnamespace.id

    subresource_names    = ["Namespace"]
    is_manual_connection = false
  }

  private_dns_zone_group {
    name                 = "example-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.example.id]
  }
  depends_on = [ azurerm_resource_group.app_grp ]
}

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = local.resource_group
  depends_on = [ azurerm_resource_group.app_grp ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example-link"
  resource_group_name   = local.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.app_network.id
  depends_on = [ azurerm_resource_group.app_grp ]
}
resource "azurerm_management_lock" "role_assignment" {
  name       = "role-asaignment"
  scope      = azurerm_role_assignment.Reader.id
  lock_level = "CanNotDelete"
  notes      = "Locked because it's needed by a third-party"
  depends_on = [ azurerm_resource_group.app_grp ]
}
# az provider register --namespace Microsoft.EventHub
