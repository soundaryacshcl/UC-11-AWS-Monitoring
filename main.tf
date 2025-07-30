# AWS Console Login Monitoring - Main Configuration
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Random suffix for unique resource naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "${var.project_name}-cloudtrail-logs-${random_string.suffix.result}"
  force_destroy = var.force_destroy_s3_bucket

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-cloudtrail-logs"
    Description = "S3 bucket for CloudTrail logs"
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-cloudtrail"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.project_name}-cloudtrail"
          }
        }
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-cloudtrail-logs"
    Description = "CloudWatch log group for CloudTrail events"
  })
}

# IAM role for CloudTrail to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name = "${var.project_name}-cloudtrail-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM policy for CloudTrail to write to CloudWatch Logs
resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name = "${var.project_name}-cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
      }
    ]
  })
}

# CloudTrail
resource "aws_cloudtrail" "main" {
  name           = "${var.project_name}-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.bucket

  # CloudWatch Logs configuration
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch_role.arn

  # Trail configuration
  include_global_service_events = true
  is_multi_region_trail        = var.multi_region_trail
  enable_log_file_validation   = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-cloudtrail"
    Description = "CloudTrail for monitoring AWS console login events"
  })

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}

# SNS topic for notifications
resource "aws_sns_topic" "console_login_alerts" {
  name = "${var.project_name}-console-login-alerts"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-console-login-alerts"
    Description = "SNS topic for AWS console login notifications"
  })
}

# SNS topic policy
resource "aws_sns_topic_policy" "console_login_alerts" {
  arn = aws_sns_topic.console_login_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = "SNS:Publish"
        Resource = aws_sns_topic.console_login_alerts.arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Email subscription to SNS topic
resource "aws_sns_topic_subscription" "email_notification" {
  count     = length(var.notification_emails)
  topic_arn = aws_sns_topic.console_login_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_emails[count.index]
}

# CloudWatch metric filter for console login events
resource "aws_cloudwatch_log_metric_filter" "console_login_filter" {
  name           = "${var.project_name}-console-login-filter"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.responseElements.ConsoleLogin = Success) }"

  metric_transformation {
    name      = "ConsoleLoginCount"
    namespace = "${var.project_name}/Security"
    value     = "1"
    default_value = "0"
  }
}

# CloudWatch alarm for console login events
resource "aws_cloudwatch_metric_alarm" "console_login_alarm" {
  alarm_name          = "${var.project_name}-console-login-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "ConsoleLoginCount"
  namespace           = "${var.project_name}/Security"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alarm_threshold
  alarm_description   = "This alarm monitors AWS console login events"
  alarm_actions       = [aws_sns_topic.console_login_alerts.arn]

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-console-login-alarm"
    Description = "CloudWatch alarm for AWS console login monitoring"
  })

  depends_on = [aws_cloudwatch_log_metric_filter.console_login_filter]
}