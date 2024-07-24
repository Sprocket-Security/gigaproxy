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

##############
# PROXY VARS #
##############

/*
  ONLY set these vars if you need the proxy instance. Otherwise, can ignore, they will do nothing
*/

variable "optional_proxy_instance" {
  description = "Whether or not to launch an AWS EC2 instance and launch mitmproxy on that instead of locally. Useful for troubleshooting."
  type = bool
  default = false
}

variable "proxy_inbound_ip_allowed" {
  description = "IP range to allow on inbound connections, including netmask. Highly recommended to set this to your own public IP address, which can be retrieved at a site like https://ipv4.rawrify.com/ip -- if you really must allow all inbound, use 0.0.0.0/0"
  type = string
  default = "127.0.0.1/32"  # Purposefully incorrect value that you must override to actually get this to work. Acts as a failsafe so you don't launch a publicly open, completely unprotected proxy instance to the internet
}

variable "proxy_public_ssh_key" {
  description = "Full content of the SSH public key pair to set on the instance. Generate an SSH key on your machine and simply supply the public keypair."
  type = string
  default = "Didn't set the SSH key properly"
}