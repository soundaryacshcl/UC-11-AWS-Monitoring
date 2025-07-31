# Variables for AWS Console Login Monitoring

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "aws-console-monitoring"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project_name))
    error_message = "Project name must contain only alphanumeric characters and hyphens."
  }
}

variable "notification_emails" {
  description = "List of email addresses to receive console login notifications"
  type        = list(string)
  
  validation {
    condition = alltrue([
      for email in var.notification_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid."
  }
}

variable "multi_region_trail" {
  description = "Whether the CloudTrail should be multi-region"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.cloudwatch_log_retention_days)
    error_message = "CloudWatch log retention days must be a valid retention period."
  }
}

variable "force_destroy_s3_bucket" {
  description = "Whether to force destroy the S3 bucket (for testing purposes)"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "aws-console-monitoring"
    ManagedBy   = "terraform"
  }
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "ap-south-1"
}

variable "alarm_threshold" {
  description = "Threshold for the CloudWatch alarm (number of login events)"
  type        = number
  default     = 1
  
  validation {
    condition     = var.alarm_threshold >= 1
    error_message = "Alarm threshold must be at least 1."
  }
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for the CloudWatch alarm"
  type        = number
  default     = 1
  
  validation {
    condition     = var.alarm_evaluation_periods >= 1 && var.alarm_evaluation_periods <= 5
    error_message = "Alarm evaluation periods must be between 1 and 5."
  }
}

variable "alarm_period_seconds" {
  description = "Period in seconds for the CloudWatch alarm evaluation"
  type        = number
  default     = 300
  
  validation {
    condition = contains([
      60, 120, 300, 600, 900, 1800, 3600
    ], var.alarm_period_seconds)
    error_message = "Alarm period must be a valid CloudWatch period."
  }
}
