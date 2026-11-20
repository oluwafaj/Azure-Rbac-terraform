data "azurerm_subscription" "primary" {
  subscription_id = var.subscription_id
}

locals {
  groups = {
    IT = {
      display_name = "IT"
      description  = "IT Operations Team - Inherits Virtual Machine Contributor role"
      role_name    = "Virtual Machine Contributor"
      users        = ["ITuser-1", "ITuser-2", "ITuser-3"]
    }
    Finance = {
      display_name = "FinanceTeam"
      description  = "Finance Team - Inherits Billing Administrator role"
      role_name    = "Billing Administrator"
      users        = ["Financeuser-1", "Financeuser-2", "Financeuser-3"]
    }
    Admin = {
      display_name = "Admin"
      description  = "Admin Team - Inherits Virtual Machine Reader role"
      role_name    = "Virtual Machine Reader" # Custom least-privilege role scoped to VMs
      users        = ["Adminuser-1", "Adminuser-2", "Adminuser-3"]
    }
  }

  # Flatten users into a map for clean resource creation
  all_users = merge([
    for group_key, group_data in local.groups : {
      for username in group_data.users : username => {
        username  = username
        group_key = group_key
      }
    }
  ]...)
}

# Creating the 3 Entra ID Security Groups
resource "azuread_group" "teams" {
  for_each = local.groups

  display_name       = each.value.display_name
  description        = each.value.description
  security_enabled   = true
  mail_enabled       = false
  assignable_to_role = each.key == "Finance" ? true : false
}

# Generating secure initial passwords for each of the 9 users
resource "random_password" "user_passwords" {
  for_each = local.all_users

  length           = 16
  special          = true
  override_special = "!@#$%^&*()-_=+"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

# Creating the 9 Entra ID Users (3 users per group)
resource "azuread_user" "team_users" {
  for_each = local.all_users

  user_principal_name   = "${lower(each.value.username)}@${var.domain_name}"
  display_name          = each.value.username
  mail_nickname         = lower(each.value.username)
  password              = random_password.user_passwords[each.key].result
  force_password_change = var.force_password_change
  account_enabled       = true
}

# Adding each user to their respective group
resource "azuread_group_member" "team_memberships" {
  for_each = local.all_users

  group_object_id  = azuread_group.teams[each.value.group_key].object_id
  member_object_id = azuread_user.team_users[each.key].object_id
}

# Assign Azure RBAC Roles to the Groups at the Subscription Scope
# Any future user added to these groups automatically inherits these roles.

# IT Group -> Virtual Machine Contributor
resource "azurerm_role_assignment" "it_vm_contributor" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azuread_group.teams["IT"].object_id
}

# Admin Group -> Virtual Machine Reader (Customised to the least privilege role scoped to VMs)
resource "azurerm_role_definition" "vm_reader_custom" {
  name        = "Virtual Machine Reader"
  scope       = data.azurerm_subscription.primary.id
  description = "Can view Virtual Machines and their metrics/configurations, but cannot modify or delete them."

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/instanceView/read",
      "Microsoft.Compute/virtualMachines/vmSizes/read",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Resources/subscriptions/resourceGroups/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id
  ]
}

resource "azurerm_role_assignment" "admin_vm_reader" {
  scope              = data.azurerm_subscription.primary.id
  role_definition_id = azurerm_role_definition.vm_reader_custom.role_definition_resource_id
  principal_id       = azuread_group.teams["Admin"].object_id
}

# Finance Group -> Billing Administrator (Entra ID Directory Role)
resource "azuread_directory_role" "billing_admin" {
  display_name = "Billing Administrator"
}

resource "azuread_directory_role_assignment" "finance_billing_admin" {
  role_id             = azuread_directory_role.billing_admin.template_id
  principal_object_id = azuread_group.teams["Finance"].object_id
}