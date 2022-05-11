resource "aws_cloudwatch_log_group" "group" {
  count = lookup(var.logging_configuration, "level", "OFF") != "OFF" && length(lookup(var.logging_configuration, "log_destination", "")) == 0 ? 1 : 0

  name              = format("aws-sfn-logs-%s", var.name)
  tags              = var.tags
  retention_in_days = lookup(var.logging_configuration, "log_retention", null)
  kms_key_id        = lookup(var.logging_configuration, "log_kms_key", null)
}

resource "aws_sfn_state_machine" "sfn" {
  name     = var.name
  tags     = var.tags
  role_arn = var.create_role ? aws_iam_role.sfn[0].arn : var.role

  type       = var.type
  definition = templatefile(var.definition_filename, var.definition_variables)

  dynamic "logging_configuration" {
    for_each = lookup(var.logging_configuration, "level", "OFF") != "OFF" ? [var.logging_configuration] : []

    content {
      include_execution_data = lookup(logging_configuration.value, "include_execution_data", null)
      level                  = lookup(logging_configuration.value, "level", "OFF")
      log_destination        = try(format("%s:*", aws_cloudwatch_log_group.group[0].arn), lookup(logging_configuration.value, "log_destination", ""))
    }
  }

  dynamic "tracing_configuration" {
    for_each = var.enable_tracing ? [true] : []

    content {
      enabled = var.enable_tracing
    }
  }
}

resource "aws_iam_role" "sfn" {
  count = var.create_role ? 1 : 0

  name = format("%s-role", var.name)
  tags = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Action = "sts:AssumeRole"

        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = concat(
    [
      "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    ],
    var.managed_policies
  )

  dynamic "inline_policy" {
    for_each = var.enable_tracing ? [true] : []

    content {
      name = "sfn-x-ray-policy"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            "Effect" : "Allow",
            "Action" : [
              "xray:PutTraceSegments",
              "xray:PutTelemetryRecords",
              "xray:GetSamplingRules",
              "xray:GetSamplingTargets"
            ],
            "Resource" : [
              "*"
            ]
          }
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = lookup(var.logging_configuration, "level", "OFF") != "OFF" ? [true] : []

    content {
      name = "sfn-cloudwatch-policy"
      policy = jsonencode({
        "Version" = "2012-10-17"
        "Statement" = [
          {
            "Sid"    = "stepFunctionAccess"
            "Effect" = "Allow"
            "Action" = [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ]
            "Resource" = length(lookup(var.logging_configuration, "log_destination", "")) != 0 ? [
              trimsuffix(lookup(var.logging_configuration, "log_destination", ""), ":*"),
              lookup(var.logging_configuration, "log_destination", "")
              ] : [
              aws_cloudwatch_log_group.group[0].arn,
              format("%s:*", aws_cloudwatch_log_group.group[0].arn)
            ]
          },
          {
            "Sid"    = "logsaccess"
            "Effect" = "Allow"
            "Action" = [
              "logs:CreateLogDelivery",
              "logs:GetLogDelivery",
              "logs:UpdateLogDelivery",
              "logs:DeleteLogDelivery",
              "logs:ListLogDeliveries",
              "logs:PutResourcePolicy",
              "logs:DescribeResourcePolicies",
              "logs:DescribeLogGroups"
            ]
            "Resource" = "*"
          }
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = var.policy

    content {
      name   = lookup(inline_policy.value, "name", "")
      policy = jsonencode(lookup(inline_policy.value, "policy", {}))
    }
  }
}
