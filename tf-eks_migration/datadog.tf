resource "aws_cloudwatch_log_subscription_filter" "test-engine-log-filter" {
  name            = "test-engine-log-filter"
  role_arn        = aws_iam_role.cloud-watch-to-kinesis-firehose.arn
  log_group_name  = aws_cloudwatch_log_group.test-engine.name
  filter_pattern  = ""
  destination_arn = "arn:aws:firehose:us-east-1:785587078662:deliverystream/DatadogCWLogsforwarder"
}


resource "aws_cloudwatch_log_subscription_filter" "platform-log-filter" {
  name            = "platform-log-filter"
  role_arn        = aws_iam_role.cloud-watch-to-kinesis-firehose.arn
  log_group_name  = aws_cloudwatch_log_group.platform.name
  filter_pattern  = "{$.full_path != \"*/health*\" || $.full_path NOT EXISTS}"
  destination_arn = "arn:aws:firehose:us-east-1:785587078662:deliverystream/DatadogCWLogsforwarder"
}

resource "aws_cloudwatch_log_subscription_filter" "router-log-filter" {
  name            = "router-log-filter"
  role_arn        = aws_iam_role.cloud-watch-to-kinesis-firehose.arn
  log_group_name  = aws_cloudwatch_log_group.router.name
  filter_pattern  = ""
  destination_arn = "arn:aws:firehose:us-east-1:785587078662:deliverystream/DatadogCWLogsforwarder"
}
