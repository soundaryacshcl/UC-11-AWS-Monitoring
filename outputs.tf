# Outputs for AWS Console Login Monitoring

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.main.arn
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail"
  value       = aws_cloudtrail.main.name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket used for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket used for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudtrail_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.cloudtrail_logs.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  value       = aws_sns_topic.console_login_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for notifications"
  value       = aws_sns_topic.console_login_alerts.name
}

output "metric_filter_name" {
  description = "Name of the CloudWatch metric filter"
  value       = aws_cloudwatch_log_metric_filter.console_login_filter.name
}

output "cloudwatch_alarm_name" {
  description = "Name of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.console_login_alarm.alarm_name
}

output "cloudwatch_alarm_arn" {
  description = "ARN of the CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.console_login_alarm.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by CloudTrail"
  value       = aws_iam_role.cloudtrail_cloudwatch_role.arn
}

output "notification_emails" {
  description = "Email addresses configured for notifications"
  value       = var.notification_emails
  sensitive   = true
}

output "account_id" {
  description = "AWS Account ID where resources are deployed"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS region where resources are deployed"
  value       = data.aws_region.current.name
}