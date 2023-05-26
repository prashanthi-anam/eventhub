resource "azurerm_user_assigned_identity" "user_managed_identity" {

  name                = "user_managed_identity"
  resource_group_name = local.resource_group
  location            = local.location
  depends_on          = [azurerm_resource_group.app_grp]
}

resource "azurerm_user_assigned_identity" "system_assigned_identity" {

  name                = "system-assigned-identity"
  resource_group_name = local.resource_group
  location            = local.location
  depends_on          = [azurerm_resource_group.app_grp]
}

resource "azurerm_role_assignment" "user_managed_role_assignment" {

  scope                = azurerm_user_assigned_identity.user_managed_identity.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.user_managed_identity.principal_id
}

resource "azurerm_role_assignment" "system_assigned_role_assignment" {

  scope                = azurerm_user_assigned_identity.system_assigned_identity.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.system_assigned_identity.principal_id
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
