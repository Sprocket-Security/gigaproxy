output "proxy-public-ip" {
  value = aws_instance.proxy-instance.public_ip
}