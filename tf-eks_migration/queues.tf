resource "aws_sqs_queue" "run_recommendation_engine" {
  name                              = "run-recommendation-engine.fifo"
  fifo_queue                        = true
  content_based_deduplication       = false
  visibility_timeout_seconds        = 600
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}

resource "aws_sqs_queue" "run_issue_source" {
  name                              = "run-issue-source.fifo"
  fifo_queue                        = true
  content_based_deduplication       = false
  visibility_timeout_seconds        = 900
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}

resource "aws_sqs_queue" "run_sync_lms_user" {
  name                              = "run-sync-lms-user.fifo"
  fifo_queue                        = true
  content_based_deduplication       = false
  visibility_timeout_seconds        = 900
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}

resource "aws_sqs_queue" "run_sync_lms" {
  name                              = "run-sync-lms.fifo"
  fifo_queue                        = true
  content_based_deduplication       = false
  visibility_timeout_seconds        = 900
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}
