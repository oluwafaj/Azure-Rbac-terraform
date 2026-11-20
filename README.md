# Azure Entra ID Groups, Users & RBAC Automation (Terraform)

This Terraform configuration automates:
1. **3 Entra ID Security Groups**: `IT`, `Finance`, and `Admin`
2. **9 Entra ID Users**:
   - `ITuser-1`, `ITuser-2`, `ITuser-3` -> added to **IT**
   - `Financeuser-1`, `Financeuser-2`, `Financeuser-3` -> added to **Finance**
   - `Adminuser-1`, `Adminuser-2`, `Adminuser-3` -> added to **Admin**
3. **Role Assignments (Group-Based Inheritance)**:
   - **IT** -> `Virtual Machine Contributor` (Azure Subscription RBAC)
   - **Admin** -> `Virtual Machine Reader` (Custom least-privilege Azure RBAC role for VM read access)
   - **Finance** -> `Billing Administrator` (Entra ID Directory Role, requires role-assignable group; note below)

## Important Notes Before Running

### 1. Required Permissions
The user or Service Principal running Terraform needs:
- **User Administrator** or **Global Administrator** in Microsoft Entra ID (to create users, groups, and directory role assignments)
- **Owner** or **User Access Administrator** on the target Azure Subscription (to assign RBAC roles and create the custom `Virtual Machine Reader` role)

### 2. Billing Administrator Directory Role & Role-Assignable Groups
In Microsoft Entra ID, assigning a Directory Role (`Billing Administrator`) to a group requires `assignable_to_role = true` on the group. If your tenant has Entra ID P1/P2 enabled, add `assignable_to_role = true` inside `resource "azuread_group" "teams"` in `main.tf`. If you only want Azure Subscription-level billing access without Entra ID P1/P2, replace `azuread_directory_role_assignment.finance_billing_admin` with an `azurerm_role_assignment` using `role_definition_name = "Billing Reader"`.

## Quick Start

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Edit `terraform.tfvars` with your `tenant_id`, `subscription_id`, and verified `domain_name` (e.g., `yourorg.onmicrosoft.com`).
3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
4. View the generated initial passwords:
   ```bash
   terraform output -json initial_user_passwords
   ```
