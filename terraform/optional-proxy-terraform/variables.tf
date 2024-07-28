variable "project_identifier" {
  default     = "gigaproxy"
  description = "Prefix value to add to resources and as a tag to relevant AWS resources."
  type        = string
}

variable "proxy_inbound_ip_allowed" {
  description = "IP range to allow on inbound connections, including netmask. Highly recommended to set this to your own public IP address, which can be retrieved at a site like https://ipv4.rawrify.com/ip -- if you really must allow all inbound, use 0.0.0.0/0"
  type        = string
}

variable "aws_region" {
  description = "Region to deploy to. Should be passed automatically from parent Terraform code."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range to use for the VPC. Doesn't affect much except the private IP address assigned to the EC2 instance, which doesn't really matter unless you're launching other services."
  type        = string
  default     = "10.99.0.0/16"
}

variable "ssh_public_key" {
  description = "Full content of the SSH public key pair to set on the instance. Generate an SSH key on your machine and simply supply the public keypair."
  type        = string
}

variable "gigaproxy_api_token" {
  description = "API token generated for gigaproxy. Highly recommended to generate a new one after you're done with the proxy instance and destroy it."
  type        = string
  sensitive   = true
}

variable "gigaproxy_endpoint" {
  description = "The API gateway execution endpoint that we can reach our gigaproxy instance on."
  type        = string
}