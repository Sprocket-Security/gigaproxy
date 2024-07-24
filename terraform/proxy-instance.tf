module "optional-proxy-instance" {
  source = "./optional-proxy-terraform"

  # Don't deploy this unless optional_proxy_instance var is set to true
  count = var.optional_proxy_instance ? 1 : 0 

  proxy_inbound_ip_allowed = var.proxy_inbound_ip_allowed
  aws_region = data.aws_region.current-region.name 
  ssh_public_key = var.proxy_public_ssh_key
}