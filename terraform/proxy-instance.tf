###########################
# OPTIONAL PROXY INSTANCE #
###########################

# READ THE README in optional-proxy-terraform/README.md

module "optional-proxy-instance" {
  source = "./optional-proxy-terraform"

  # Don't deploy this unless optional_proxy_instance var is set to true
  count = var.optional_proxy_instance ? 1 : 0

  proxy_inbound_ip_allowed = var.proxy_inbound_ip_allowed
  aws_region               = data.aws_region.current-region.name
  ssh_public_key           = var.proxy_public_ssh_key
  gigaproxy_api_token      = aws_api_gateway_api_key.proxy-api-key.value
  gigaproxy_endpoint       = aws_api_gateway_deployment.v1-deployment.invoke_url
}

output "proxy-public-ip" {
  value = var.optional_proxy_instance ? "Proxy instance public IP: ${module.optional-proxy-instance[0].proxy-public-ip}" : null
}