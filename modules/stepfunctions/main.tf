# Step Functions Module - Learning Example
# This module creates a simple Step Function with 3 Lambda functions connected to S3

# AWS Provider Configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "kai-labs"
}

# S3 Bucket for Step Functions data
resource "aws_s3_bucket" "stepfunctions_data" {
  bucket = "${var.name}-stepfunctions-data"

  tags = merge(var.common_tags, {
    Name = "${var.name}-stepfunctions-data"
  })
}

resource "aws_s3_bucket_versioning" "stepfunctions_data" {
  bucket = aws_s3_bucket.stepfunctions_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "stepfunctions_data" {
  bucket = aws_s3_bucket.stepfunctions_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM Role for Step Functions
resource "aws_iam_role" "stepfunctions_role" {
  name = "${var.name}-stepfunctions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.name}-stepfunctions-role"
  })
}

# IAM Policy for Step Functions
resource "aws_iam_role_policy" "stepfunctions_policy" {
  name = "${var.name}-stepfunctions-policy"
  role = aws_iam_role.stepfunctions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.processor.arn,
          aws_lambda_function.validator.arn,
          aws_lambda_function.notifier.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.stepfunctions_data.arn}/*"
        ]
      }
    ]
  })
}

# IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.name}-lambda-role"
  })
}

# IAM Policy for Lambda Functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.name}-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.stepfunctions_data.arn}/*"
        ]
      }
    ]
  })
}

# CloudWatch Log Group for Lambda Functions
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.name}-stepfunctions"
  retention_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.name}-lambda-logs"
  })
}

# Lambda Function 1: Data Validator
resource "aws_lambda_function" "validator" {
  filename         = "lambda_validator.zip"
  function_name    = "${var.name}-validator"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.stepfunctions_data.bucket
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_logs]

  tags = merge(var.common_tags, {
    Name = "${var.name}-validator"
  })
}

# Lambda Function 2: Data Processor
resource "aws_lambda_function" "processor" {
  filename         = "lambda_processor.zip"
  function_name    = "${var.name}-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.stepfunctions_data.bucket
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_logs]

  tags = merge(var.common_tags, {
    Name = "${var.name}-processor"
  })
}

# Lambda Function 3: Notification Sender
resource "aws_lambda_function" "notifier" {
  filename         = "lambda_notifier.zip"
  function_name    = "${var.name}-notifier"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.stepfunctions_data.bucket
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_logs]

  tags = merge(var.common_tags, {
    Name = "${var.name}-notifier"
  })
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "data_pipeline" {
  name     = "${var.name}-data-pipeline"
  role_arn = aws_iam_role.stepfunctions_role.arn

  definition = jsonencode({
    Comment = "Simple data processing pipeline"
    StartAt = "ValidateData"
    States = {
      ValidateData = {
        Type     = "Task"
        Resource = aws_lambda_function.validator.arn
        Next     = "ProcessData"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
            IntervalSeconds = 2
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "HandleError"
            ResultPath = "$.error"
          }
        ]
      }
      ProcessData = {
        Type     = "Task"
        Resource = aws_lambda_function.processor.arn
        Next     = "SendNotification"
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
            IntervalSeconds = 2
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "HandleError"
            ResultPath = "$.error"
          }
        ]
      }
      SendNotification = {
        Type     = "Task"
        Resource = aws_lambda_function.notifier.arn
        End      = true
        Retry = [
          {
            ErrorEquals = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
            IntervalSeconds = 2
            MaxAttempts = 3
            BackoffRate = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next = "HandleError"
            ResultPath = "$.error"
          }
        ]
      }
      HandleError = {
        Type = "Fail"
        Cause = "Data processing failed"
        Error = "ProcessingError"
      }
    }
  })

  tags = merge(var.common_tags, {
    Name = "${var.name}-data-pipeline"
  })
}

