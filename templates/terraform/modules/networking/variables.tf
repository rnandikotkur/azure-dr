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

variable "existing_vnet_id" {
  description = "ID of existing VNet if using one"
  type        = string
  default     = ""
}

variable "address_space" {
  description = "Address space for new VNet if created"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "gateway_subnet_cidr" {
  description = "CIDR for Gateway subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "apim_subnet_cidr" {
  description = "CIDR for API Management subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ase_subnet_cidr" {
  description = "CIDR for App Service Environment subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "container_subnet_cidr" {
  description = "CIDR for Container App Environment subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}