# Example Terraform variables file
# Copy this file to terraform.tfvars and customize the values

# Project configuration
project_name = "aws-console-monitoring"
aws_region   = "us-east-1"

# Email notifications - REQUIRED
# Replace with actual email addresses that should receive notifications
notification_emails = [
  "soundaryacshcl@gmail.com"
]

# CloudTrail configuration
multi_region_trail = true

# CloudWatch configuration
cloudwatch_log_retention_days = 30

# Alarm configuration
alarm_threshold          = 1
alarm_evaluation_periods = 1
alarm_period_seconds     = 300

# S3 configuration (for testing environments only)
force_destroy_s3_bucket = false

# Common tags applied to all resources
common_tags = {
  Environment = "production"
  Project     = "aws-console-monitoring"
  Owner       = "security-team"
  ManagedBy   = "terraform"
  CostCenter  = "security"
}
