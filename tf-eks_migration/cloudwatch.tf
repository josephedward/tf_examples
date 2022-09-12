# Log groups

resource "aws_cloudwatch_log_group" "test-engine" {
  name = "/hackedu/platform/test-engine"

  tags = {
    Environment = var.public.environment
  }
}

resource "aws_cloudwatch_log_group" "platform" {
  name = "/hackedu/platform"

  tags = {
    Environment = var.public.environment
  }
}

resource "aws_cloudwatch_log_group" "router" {
  name = "/hackedu/platform/router"

  tags = {
    Environment = var.public.environment
  }
}

# Log metric filters
variable "metric-test-engine-error" {
  type = map(string)

  default = {
    name      = "test-engine/error"
    namespace = "Platform"
  }
}

resource "aws_cloudwatch_log_metric_filter" "test-engine-error" {
  name           = "Log Errors"
  pattern        = "{ $.level = 50 }"
  log_group_name = aws_cloudwatch_log_group.test-engine.name

  metric_transformation {
    name          = var.metric-test-engine-error["name"]
    namespace     = var.metric-test-engine-error["namespace"]
    value         = "1"
    default_value = "0"
  }
}

variable "metric-router-error" {
  type = map(string)

  default = {
    name      = "router/error"
    namespace = "Platform"
  }
}

resource "aws_cloudwatch_log_metric_filter" "router-error" {
  name           = "Log Errors"
  pattern        = "{ $.level = 50 }"
  log_group_name = aws_cloudwatch_log_group.router.name

  metric_transformation {
    name          = var.metric-router-error["name"]
    namespace     = var.metric-router-error["namespace"]
    value         = "1"
    default_value = "0"
  }
}

variable "metric-platform-error" {
  type = map(string)

  default = {
    name      = "platform/error"
    namespace = "Platform"
  }
}

resource "aws_cloudwatch_log_metric_filter" "platform-error" {
  name           = "Log Errors"
  pattern        = "{ $.level = 50 }"
  log_group_name = aws_cloudwatch_log_group.platform.name

  metric_transformation {
    name          = var.metric-platform-error["name"]
    namespace     = var.metric-platform-error["namespace"]
    value         = "1"
    default_value = "0"
  }
}
