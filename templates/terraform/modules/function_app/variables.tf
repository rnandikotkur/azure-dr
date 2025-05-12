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

variable "name" {
  description = "Name of the Function App"
  type        = string
}

variable "app_service_plan_id" {
  description = "ID of the App Service Plan"
  type        = string
}

variable "os_type" {
  description = "OS type for the Function App (Linux or Windows)"
  type        = string
  default     = "Linux"
  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "The os_type must be either 'Linux' or 'Windows'."
  }
}

variable "dotnet_version" {
  description = ".NET version"
  type        = string
  default     = null
}

variable "java_version" {
  description = "Java version"
  type        = string
  default     = null
}

variable "node_version" {
  description = "Node.js version"
  type        = string
  default     = null
}

variable "python_version" {
  description = "Python version (Linux only)"
  type        = string
  default     = null
}

variable "functions_worker_runtime" {
  description = "Functions worker runtime"
  type        = string
  default     = "dotnet"
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/api/health"
}

variable "health_check_eviction_time_in_min" {
  description = "Health check eviction time in minutes"
  type        = number
  default     = 5
}

variable "app_settings" {
  description = "Application settings"
  type        = map(string)
  default     = {}
}

variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}