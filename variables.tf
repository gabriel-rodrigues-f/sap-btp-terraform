variable "global_account_domain" {
  description = "Global Acocunt domain"
  type        = string
}

variable "subaccount_admin" {
  description = "Default subaccount admin"
  type        = string
}

variable "env" {
  description = "Corporate environment"
  type        = string
}

variable "cloud_foundry_api" {
  description = "SAP P-User"
  type        = string
}

variable "cloud_foundry_user" {
  description = "SAP P-User"
  type        = string
}

variable "cloud_foundry_password" {
  description = "Default user"
  type        = string
}
