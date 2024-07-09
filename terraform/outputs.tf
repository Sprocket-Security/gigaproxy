output "api-endpoint" {
  value = "${aws_api_gateway_stage.v1-stage.invoke_url}/gigaproxy-forwarder-function"
}