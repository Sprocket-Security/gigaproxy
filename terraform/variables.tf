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