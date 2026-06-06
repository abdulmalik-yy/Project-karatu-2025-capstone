output "cwagent_role_arn" {
  description = "ARN of the CloudWatch Agent IAM role"
  value       = aws_iam_role.cwagent_role.arn
}



output "application_log_group_arn" {
  description = "ARN of the application CloudWatch log group"
  value       = aws_cloudwatch_log_group.application_logs.arn
}

output "dataplane_log_group_arn" {
  description = "ARN of the dataplane CloudWatch log group"
  value       = aws_cloudwatch_log_group.dataplane_logs.arn
}

output "bedrock_dev_password" {
  description = "Password for the bedrock-dev-view user"
  value       = aws_iam_user_login_profile.dev.password
}

output "bedrock_dev_access_key" {
  description = "Access key ID for the bedrock-dev-view user"
  value       = aws_iam_access_key.dev.id
}

output "bedrock_dev_secret_key" {
  description = "Secret access key for the bedrock-dev-view user"
  value       = aws_iam_access_key.dev.secret
}