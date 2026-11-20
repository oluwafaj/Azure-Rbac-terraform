variable "tenant_id" {
  description = "The Entra ID (Azure AD) Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "The Azure Subscription ID where RBAC roles will be assigned"
  type        = string
}

variable "domain_name" {
  description = "Verified Entra ID primary domain name (e.g., contoso.onmicrosoft.com)"
  type        = string
}

variable "force_password_change" {
  description = "Require users to change their password on first login"
  type        = bool
  default     = true
}
