###########################
# OPTIONAL PROXY INSTANCE #
###########################

/*
    Can't get the mitmproxy stuff working? You can optionally use this to launch a persistent EC2 instance that'll 
*/

# Use latest ARM-based Ubuntu 22.04
data "aws_ami" "latest-ubuntu-arm" {  
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "ssh-keypair" {  
  key_name = "${var.project_identifier}-temp-proxy-instance-key"
  public_key = var.ssh_public_key
}


resource "aws_instance" "proxy-instance" {

  ami = data.aws_ami.latest-ubuntu-arm.id
  instance_type = "t4g.micro"
  
  source_dest_check = false

  vpc_security_group_ids = [aws_security_group.proxy-sg.id]
  subnet_id = module.proxy-vpc.public_subnets[0]

  key_name = aws_key_pair.ssh-keypair.id

  user_data_base64 = filebase64("${path.module}/proxy-instance-bootstrap.sh")

  root_block_device {
    encrypted = true 
  }

  tags = {
    Name = "${var.project_identifier}-temporary-proxy-instance"
  }
}


#################################
# NETWORKING FOR OPTIONAL PROXY #
#################################

module "proxy-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.9.0"

  name = "${var.project_identifier}-vpc"
  cidr = var.vpc_cidr

  azs = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets = ["10.99.0.0/24", "10.99.1.0/24"]
  
  map_public_ip_on_launch = true 
}

resource "aws_security_group" "proxy-sg" {
  name = "${var.project_identifier}-sg"
  description = "For the ${var.project_identifier} proxy EC2 instance"
  vpc_id = module.proxy-vpc.vpc_id 
}

resource "aws_vpc_security_group_egress_rule" "proxy-sg-egress" {
  security_group_id = aws_security_group.proxy-sg.id
  description = "Allow outbound"

  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "proxy-sg-inbound-ssh" {
  security_group_id = aws_security_group.proxy-sg.id
  description = "Allow inbound ssh"

  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_ipv4 = var.proxy_inbound_ip_allowed
}

resource "aws_vpc_security_group_ingress_rule" "proxy-sg-inbound-http" {
  security_group_id = aws_security_group.proxy-sg.id
  description = "Allow inbound http"

  ip_protocol = "tcp"
  from_port = 80
  to_port = 80
  cidr_ipv4 = var.proxy_inbound_ip_allowed
}

resource "aws_vpc_security_group_ingress_rule" "proxy-sg-inbound-https" {
  security_group_id = aws_security_group.proxy-sg.id
  description = "Allow inbound https"

  ip_protocol = "tcp"
  from_port = 443
  to_port = 443
  cidr_ipv4 = var.proxy_inbound_ip_allowed
}