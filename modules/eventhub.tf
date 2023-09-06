data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "example" {
}

resource "azurerm_role_assignment" "Reader" {
  scope                = azurerm_eventhub.testeventhub.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_client_config.example.object_id
}

resource "azurerm_role_assignment" "eventhub_storage_blobs_write" {
  scope                = azurerm_storage_account.appstore.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.example.object_id
}

resource "azurerm_resource_group" "app_grp" {
    name = var.resource_group
    location = var.location
    
  
}

resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = var.location
  resource_group_name = var.resource_group
  address_space       = ["${var.vnet_address_space}"]
  depends_on = [ azurerm_resource_group.app_grp ]
}

resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["${var.subnet_address_prefix}"]
  depends_on = [
    azurerm_virtual_network.app_network
  ]
}

resource "azurerm_public_ip" "app_public_ip" {
  name                = "app-public-ip"
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = "Static"
  depends_on = [ azurerm_resource_group.app_grp ]
}
resource "azurerm_network_interface" "app_interface" {
  name                = "app-interface"
  location            = var.location
  resource_group_name = var.resource_group

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
  resource_group_name      = var.resource_group
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
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
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = var.sku
  depends_on = [ azurerm_resource_group.app_grp ]
}
resource "azurerm_eventhub" "testeventhub" {
  name                = "test-eventhub"
  namespace_name      = azurerm_eventhub_namespace.testeventhubnamespace.name
  resource_group_name = var.resource_group
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
  location            = var.location
  resource_group_name = var.resource_group
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
  resource_group_name = var.resource_group
  depends_on = [ azurerm_resource_group.app_grp ]
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example-link"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.app_network.id
  depends_on = [ azurerm_resource_group.app_grp ]
}
resource "azurerm_management_lock" "role_assignment" {
  name       = "role-asaignment"
  scope      = azurerm_eventhub_namespace.testeventhubnamespace.id
  lock_level = "CanNotDelete"
  notes      = "Locked because it's needed by a third-party"
  depends_on = [ azurerm_resource_group.app_grp ]
}
# az provider register --namespace Microsoft.EventHub
