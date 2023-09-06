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
resource "azurerm_monitor_action_group" "main" {
  name                = "example-actiongroup"
  resource_group_name = local.resource_group
  short_name          = "exampleact"
 email_receiver {
    name                    = "email-receiver"
    email_address           = "anamprashanthireddy@gmail.com"  # Replace with your email address
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "example" {
  name                = "example-metricalert"
  resource_group_name = local.resource_group
  scopes              = [azurerm_storage_account.appstore.id]
  description         = "Action will be triggered when Transactions count is greater than 50."

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 1

    dimension {
      name     = "ApiName"
      operator = "Include"
      values   = ["appstore457768714567"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
resource "azurerm_monitor_action_group" "eventhub" {
  name                = "eventhub-actiongroup"
  resource_group_name = local.resource_group
  short_name          = "exampleact"

  email_receiver {
    name                    = "email-receiver"
    email_address           = "anamprashanthireddy@gmail.com"  # Replace with your email address
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "eventhubalert" {
  name                = "example-metriceventhubalert"
  resource_group_name = local.resource_group
  scopes              = [azurerm_eventhub_namespace.testeventhubnamespace.id]
  description         = "Action will be triggered when Transactions count is greater than 50."

  criteria {
    metric_namespace = "Microsoft.EventHub/namespaces"
    metric_name      = "ActiveConnections"
    aggregation      = "Maximum" 
    operator         = "GreaterThan"
    threshold        = 1

   
  }

  action {
    action_group_id = azurerm_monitor_action_group.eventhub.id
  }
}
