variable "environment" {
  description = "Environment name (dev, test, prod, etc.)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "Azure region"
  type        = string
  default     = "North Central US"
}

variable "region_short" {
  description = "Short name for the Azure region"
  type        = string
  default     = "ncus"
}

variable "existing_vnet_id" {
  description = "ID of existing VNet"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}