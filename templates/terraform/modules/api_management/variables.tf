variable "region" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "publisher_name" {
  description = "Publisher name for the API Management service"
  type        = string
  default     = "Contoso"
}

variable "publisher_email" {
  description = "Publisher email for the API Management service"
  type        = string
  default     = "admin@contoso.com"
}

variable "sku_name" {
  description = "SKU for the API Management service"
  type        = string
  default     = "Developer_1"
}

variable "subnet_id" {
  description = "Subnet ID for the API Management service"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}