output "s3_bucket_name" {
  description = "Name of the S3 bucket for Step Functions data"
  value       = aws_s3_bucket.stepfunctions_data.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Step Functions data"
  value       = aws_s3_bucket.stepfunctions_data.arn
}

output "stepfunctions_state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.data_pipeline.arn
}

output "stepfunctions_state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.data_pipeline.name
}

output "lambda_validator_arn" {
  description = "ARN of the validator Lambda function"
  value       = aws_lambda_function.validator.arn
}

output "lambda_processor_arn" {
  description = "ARN of the processor Lambda function"
  value       = aws_lambda_function.processor.arn
}

output "lambda_notifier_arn" {
  description = "ARN of the notifier Lambda function"
  value       = aws_lambda_function.notifier.arn
}

