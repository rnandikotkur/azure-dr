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

variable "subnet_id" {
  description = "Subnet ID for the Container App Environment"
  type        = string
}

variable "zone_redundancy_enabled" {
  description = "Whether to enable zone redundancy"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}