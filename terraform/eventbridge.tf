# We need to do some re-parsing since jsonencode will escape < and >
locals {
  schedule_input = jsonencode({
    "FunctionName" : aws_lambda_function.forwarder-function.function_name
    "Description" : "redeployed by eventbridge at <aws.scheduler.scheduled-time>"
  })

  corrected_schedule_input = replace(replace(local.schedule_input, "\\u003c", "<"), "\\u003e", ">")
}

#####################################
# EVENTBRIDGE SCHEDULE TO ROTATE IP #
#####################################

resource "aws_scheduler_schedule" "cycle-lambda-ips" {
  name       = "${var.project_identifier}-redeploy-ip-rotation"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 minutes)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:lambda:updateFunctionConfiguration"
    role_arn = aws_iam_role.eventbridge-role.arn

    input = local.corrected_schedule_input
  }
}


#######################################
# IAM POLICY FOR EVENTBRIDGE SCHEDULE #
#######################################
data "aws_iam_policy_document" "eventbridge-assume-role" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "scheduler.amazonaws.com"
      ]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "eventbridge-role" {
  name               = "${var.project_identifier}-eventbridge-cron-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge-assume-role.json
}

data "aws_iam_policy_document" "eventbridge-permissions" {
  statement {
    sid    = "AllowUpdateLambda"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration"
    ]
    resources = [
      "arn:aws:lambda:*:${data.aws_caller_identity.current-account.account_id}:function:${var.project_identifier}-*"
    ]
  }
}

resource "aws_iam_policy" "eventbridge-policy" {
  name   = "${var.project_identifier}-eventbridge-cron-policy"
  policy = data.aws_iam_policy_document.eventbridge-permissions.json
}

resource "aws_iam_role_policy_attachment" "eventbridge-policy-attach" {
  role       = aws_iam_role.eventbridge-role.name
  policy_arn = aws_iam_policy.eventbridge-policy.arn
}