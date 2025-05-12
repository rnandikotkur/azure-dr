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
  description = "Subnet ID for the App Service Environment"
  type        = string
}

variable "dedicated_host_count" {
  description = "Number of dedicated hosts"
  type        = number
  default     = 2
}

variable "zone_redundant" {
  description = "Whether to enable zone redundancy"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}