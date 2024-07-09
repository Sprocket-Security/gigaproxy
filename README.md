## Gigaproxy

Fast and cheap IP rotation using AWS API Gateway and Lambda.

## Prerequisites
- An AWS account
- AWS credentials set locally (AWS SSO session, static access keys, whatever floats your boat)
- Hashicorp Terraform installed locally
- Python installed locally

## Getting Started

### Terraform Build Steps
- Open a terminal session to this project directory
- `cd terraform/`
- `terraform init` 
- `terraform plan` - optional: if you want to see what's going to be built before running apply
- `terraform apply`
- Look for the output `api-endpoint` in your terminal after applying

### Hitting the API
- Using the `api-endpoint` value from above, send a request to the API with the following headers:
    - `x-api-key`, with a value of your API key (if you didn't set one manually in the Terraform code, check your AWS console)
    - `x-forward-me-to`, with a value of whatever you actually want to hit (e.g. `https://ipv4.rawrify.com/ip`)
