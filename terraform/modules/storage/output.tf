output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.project-bedrock-bucket.arn
}

output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.project-bedrock-bucket.id
}

output "lambda_function_arn" {
  description = "The ARN of the lambda function"
  value       = aws_lambda_function.bedrock-assets-lambda.arn
}

output "lambda_function_name" {
  description = "The name of the lambda function"
  value       = aws_lambda_function.bedrock-assets-lambda.function_name
}