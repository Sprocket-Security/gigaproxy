# Minimal AWS provider definition, really only for enforcing default tags
# Use AWS environment variables (e.g. AWS_PROFILE, AWS_REGION) for auth config
provider "aws" {
  default_tags {
    tags = {
      Project   = var.project_identifier
      Terraform = true
    }
  }
}

data "aws_caller_identity" "current-account" {

}

data "aws_region" "current-region" {

}
