# Step Functions Module

This module creates a simple AWS Step Functions workflow with 3 Lambda functions connected to S3 for learning purposes.

## Architecture

The module creates:

1. **S3 Bucket** - For storing data at different stages of processing
2. **3 Lambda Functions**:
   - **Validator** - Validates incoming data
   - **Processor** - Processes the validated data
   - **Notifier** - Sends notifications about completed processing
3. **Step Functions State Machine** - Orchestrates the workflow
4. **IAM Roles and Policies** - For secure access to AWS services

## Workflow

```
Input Data → Validator → Processor → Notifier → Complete
```

1. **Validator**: Checks if data has required fields (`id`, `message`)
2. **Processor**: Transforms the data (e.g., converts message to uppercase)
3. **Notifier**: Creates a notification and stores it in S3

## Usage

### Prerequisites

1. AWS CLI configured with `kai-labs` profile
2. Package the Lambda functions:
   ```bash
   cd modules/stepfunctions
   ./package_lambda.sh
   ```

### Deploy the Module

```hcl
module "stepfunctions" {
  source = "./modules/stepfunctions"
  
  name = "my-learning"
  
  common_tags = {
    Environment = "learning"
    Project     = "stepfunctions-demo"
  }
}
```

### Test the Workflow

1. **Start the Step Function**:
   ```bash
   aws stepfunctions start-execution \
     --state-machine-arn <STATE_MACHINE_ARN> \
     --input '{"data": {"id": "test-001", "message": "Hello World"}}' \
     --profile kai-labs
   ```

2. **Check Execution Status**:
   ```bash
   aws stepfunctions describe-execution \
     --execution-arn <EXECUTION_ARN> \
     --profile kai-labs
   ```

3. **View Results in S3**:
   ```bash
   aws s3 ls s3://<BUCKET_NAME>/validated/ --profile kai-labs
   aws s3 ls s3://<BUCKET_NAME>/processed/ --profile kai-labs
   aws s3 ls s3://<BUCKET_NAME>/notifications/ --profile kai-labs
   ```

## Files Structure

```
modules/stepfunctions/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── lambda_validator.py        # Validator Lambda function code
├── lambda_processor.py        # Processor Lambda function code
├── lambda_notifier.py         # Notifier Lambda function code
├── package_lambda.sh          # Script to package Lambda functions
└── README.md                  # This file
```

## Learning Points

1. **Step Functions**: Learn how to orchestrate multiple Lambda functions
2. **Lambda Functions**: Understand serverless compute with Python
3. **S3 Integration**: See how to store and retrieve data from S3
4. **IAM Roles**: Learn about AWS security and permissions
5. **Error Handling**: See how Step Functions handle failures and retries
6. **State Machine**: Understand workflow orchestration concepts

## Cost Considerations

- **Lambda**: Pay per request and execution time
- **Step Functions**: Pay per state transition
- **S3**: Pay for storage and requests
- **CloudWatch Logs**: Pay for log storage

This is a simple, cost-effective learning example that demonstrates core AWS serverless concepts.
