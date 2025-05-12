variable "environment" {
  description = "Environment name (dev, test, prod, etc.)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "Azure region"
  type        = string
  default     = "South Central US"
}

variable "region_short" {
  description = "Short name for the Azure region"
  type        = string
  default     = "scus"
}

variable "existing_vnet_id" {
  description = "ID of existing VNet"
  type        = string
  default     = ""
}

variable "deploy_compute" {
  description = "Whether to deploy compute resources"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Role        = "DisasterRecovery"
  }
}