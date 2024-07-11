data "archive_file" "lambda-function-zip" {
  type        = "zip"
  source_file = "${path.module}/src/forwarder-function/lambda_function.py"
  output_path = "${path.module}/builds/lambda_function_payload.zip"
}

##########################################################################
# LAMBDA FUNCTION THAT FORWARDS YOUR TRAFFIC - THIS IS WHERE IT GOES OUT #
##########################################################################

resource "aws_lambda_function" "forwarder-function" {
  function_name = "${var.project_identifier}-forwarder-function"
  description   = "Forwarding function for the ${var.project_identifier} API"

  role = aws_iam_role.forwarder-function-role.arn

  handler = "lambda_function.lambda_handler"

  filename         = "${path.module}/builds/lambda_function_payload.zip"
  source_code_hash = data.archive_file.lambda-function-zip.output_base64sha256
  runtime          = "python3.12"

  timeout     = 10
  memory_size = 128

  layers = [
    aws_lambda_layer_version.dependencies-layer.arn
  ]
}

########################################
# IAM POLICY STUFF FOR LAMBDA FUNCTION #
########################################

data "aws_iam_policy_document" "lambda-assume-role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "forwarder-function-role" {
  name               = "${var.project_identifier}-function-role"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role.json
}

# Attach the basic AWS Lambda execution role, which allows the Lambda to log to Cloudwatch
resource "aws_iam_role_policy_attachment" "attach-basic-lambda-policy" {
  count = var.enable_function_logging ? 1 : 0 

  role = aws_iam_role.forwarder-function-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "invoke-from-api" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.forwarder-function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gigaproxy-api.execution_arn}/*"
}

# Package dependencies for the forwarder function
resource "aws_lambda_layer_version" "dependencies-layer" {
  layer_name = "${var.project_identifier}-dependencies-layer"
  filename   = "${path.module}/src/dependencies.zip"

  source_code_hash = filebase64sha256("${path.module}/src/dependencies.zip")

  compatible_architectures = ["arm64"]
  compatible_runtimes      = ["python3.12"]
}

#####################################
# CLOUDWATCH LOG GROUP FOR FUNCTION #
#####################################

# Create a log group and set default retention to 14 days so we don't get a crapload of logs just sitting there
resource "aws_cloudwatch_log_group" "lambda-function-logs" {
  count = var.enable_function_logging ? 1 : 0 
  
  name = "/aws/lambda/${aws_lambda_function.forwarder-function.function_name}"

  retention_in_days = var.log_retention_period
}