terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.49.0"
    }
  }
}
module "eventhub" {
  source                   = "./modules"
  resource_group           = "rg-1"
  location                 = "East Us"
  lock_level               = "CanNotDelete"
  sku                      = "Standard"
  account_replication_type = "LRS"
  account_tier             = "Standard"
  vnet_address_space       = "10.0.0.0/16"
  subnet_address_prefix    = "10.0.2.0/24"


}