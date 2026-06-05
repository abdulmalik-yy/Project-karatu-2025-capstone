#--BUCKET--#

resource "aws_s3_bucket" "project-bedrock-bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_versioning" "bedrock-assets-versioning" {
  bucket = aws_s3_bucket.project-bedrock-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bedrock-assets-public-access-block" {
  bucket                  = aws_s3_bucket.project-bedrock-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "bedrock-assets-kms-key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  tags = {
    Name = "bedrock-assets-kms-key"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bedrock-assets-sse-config" {
  bucket = aws_s3_bucket.project-bedrock-bucket.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bedrock-assets-kms-key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

#--LAMBDA IAM ROLE--#

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda-role" {
  name               = "bedrock-assets-processor-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags = {
    Name = "bedrock-assets-processor-role"
  }
}

resource "aws_iam_role_policy_attachment" "bedrock-assets-processor-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.lambda-role.name
}

#--LAMBDA FUNCTION--#
data "archive_file" "bedrock-assets-lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../../scripts/lambda"
  output_path = "lambda-function.zip"
}

resource "aws_cloudwatch_log_group" "bedrock-assets-lambda-logs" {
  name              = "/aws/lambda/${aws_lambda_function.bedrock-assets-lambda.function_name}"
  retention_in_days = 14
  tags = {
    Name = "bedrock-assets-lambda-logs"
  }
}

resource "aws_lambda_function" "bedrock-assets-lambda" {
  function_name    = "bedrock-assets-processor"
  filename         = data.archive_file.bedrock-assets-lambda.output_path
  source_code_hash = data.archive_file.bedrock-assets-lambda.output_base64sha256
  role             = aws_iam_role.lambda-role.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.project-bedrock-bucket.id
    }
  }

  tags = {
    Name = "bedrock-assets-processor"
  }
}

#--LAMBDA PERMISSION--#

resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3ToInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bedrock-assets-lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.project-bedrock-bucket.arn
}

#--S3 EVENT NOTIFICATION--#

resource "aws_s3_bucket_notification" "bedrock-assets-notification" {
  bucket = aws_s3_bucket.project-bedrock-bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.bedrock-assets-lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_trigger]
}