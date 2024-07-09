#####################################
# REST API - SEND YOUR TRAFFIC HERE #
#####################################

resource "aws_api_gateway_rest_api" "gigaproxy-api" {
  name = "${var.project_identifier}-api"

  description = "${var.project_identifier} REST API"

  # Body defined as OpenAPI v3 JSON -- can use Swagger too
  body = jsonencode(
    {
      "openapi" : "3.0.1",
      "paths" : {
        "/gigaproxy-forwarder-function" : {
          "x-amazon-apigateway-any-method" : {
            "responses" : {
              "200" : {
                "description" : "200 response",
                "content" : {}
              }
            },
            "security" : [{
              "api_key" : []
            }],
            "x-amazon-apigateway-integration" : {
              "httpMethod" : "POST",
              "uri" : "arn:aws:apigateway:${data.aws_region.current-region.name}:lambda:path/2015-03-31/functions/arn:aws:lambda:${data.aws_region.current-region.name}:${data.aws_caller_identity.current-account.account_id}:function:${var.project_identifier}-forwarder-function/invocations",
              "responses" : {
                "default" : {
                  "statusCode" : "200"
                }
              },
              "passthroughBehavior" : "when_no_templates",
              "contentHandling" : "CONVERT_TO_TEXT",
              "type" : "aws_proxy"
            }
          }
        }
      },
      "components" : {
        "securitySchemes" : {
          "api_key" : {
            "type" : "apiKey",
            "name" : "x-api-key",
            "in" : "header"
          }
        }
      },
      "x-amazon-apigateway-binary-media-types" : ["image/jpg", "image/gif", "image/png"]
    }
  )

  endpoint_configuration {
    types = ["REGIONAL"] # Can set to edge-optimized if you want, but only really affects inbound latency to API Gateway from clients geographically dispersed across the world. Doesn't really affect IP rotation
  }
}

resource "aws_api_gateway_stage" "v1-stage" {
  stage_name    = "v1"
  rest_api_id   = aws_api_gateway_rest_api.gigaproxy-api.id
  deployment_id = aws_api_gateway_deployment.v1-deployment.id
}

resource "aws_api_gateway_deployment" "v1-deployment" {
  rest_api_id = aws_api_gateway_rest_api.gigaproxy-api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.gigaproxy-api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create an AWS API Gateway REST API API key for auth and usage control
resource "aws_api_gateway_api_key" "proxy-api-key" {
  name  = "${var.project_identifier}-api-key"
  value = var.api_key == "" ? null : var.api_key
}

resource "aws_api_gateway_usage_plan" "proxy-usage-plan" {
  name        = "${var.project_identifier}-usage-plan"
  description = "Controls access to and usage for the ${var.project_identifier} proxy"

  api_stages {
    api_id = aws_api_gateway_rest_api.gigaproxy-api.id
    stage  = aws_api_gateway_stage.v1-stage.stage_name
  }

  quota_settings {
    limit  = 20000000 # By default, limit to 20 million requests per month. Can be modified or fully removed for no cap
    period = "MONTH"
  }
}

resource "aws_api_gateway_usage_plan_key" "link-proxy-key" {
  key_id        = aws_api_gateway_api_key.proxy-api-key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.proxy-usage-plan.id
}