variable "project_identifier" {
  default     = "gigaproxy"
  description = "Prefix value to add to resources and as a tag to relevant AWS resources."
  type        = string
}

variable "api_key" {
  description = "Value to set for API key for authentication. If not set, AWS sets it automatically (and can be retrieved from API Gateway console)."
  sensitive   = true
  type        = string
  default     = ""
}

variable "enable_function_logging" {
  description = "Whether or not to enable logging on the forwarder Lambda function. Defaults to false (no logging)"
  type = bool
  default = false
}

variable "log_retention_period" {
  description = "Duration for how long logs should be kept for the forwarder function in days. Defaults to 14 days."
  type = number
  default = 14
}

variable "api_monthly_quota" {
  description = "Number of requests to allow per month to the proxy API. Defaults to 10 million. Don't rely on this too much as a hard cap, there can be some wiggle room in how this is enforced (per AWS documentation)"
  type = number
  default = 10000000
}