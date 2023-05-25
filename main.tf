

locals {
  resource_group = "rg-1"
  location       = "East US"
}



resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = local.resource_group
  address_space       = ["10.0.0.0/16"]

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
  name                     = "appstore45776871909"
  resource_group_name      = local.resource_group
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"


}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = "appstore45776871909"
  container_access_type = "blob"
  depends_on = [
    azurerm_storage_account.appstore
  ]
}

resource "azurerm_eventhub_namespace" "testeventhubnamespace" {
  name                = "testeventhub1220301"
  location            = local.location
  resource_group_name = local.resource_group
  sku                 = "Standard"
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
}

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = local.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example-link"
  resource_group_name   = local.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = azurerm_virtual_network.app_network.id
}


