# Example usage of the Step Functions module
# This file shows how to use the Step Functions module for learning purposes

module "stepfunctions_learning" {
  source = "./modules/stepfunctions"
  
  name = "opencti-demo"
  
  common_tags = {
    Environment = "learning"
    Project     = "opencti-demo"
    Module      = "stepfunctions"
  }
}

# Output the important values for testing
output "stepfunctions_bucket_name" {
  description = "Name of the S3 bucket for Step Functions data"
  value       = module.stepfunctions_learning.s3_bucket_name
}

output "stepfunctions_state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.stepfunctions_learning.stepfunctions_state_machine_arn
}

output "stepfunctions_state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = module.stepfunctions_learning.stepfunctions_state_machine_name
}
