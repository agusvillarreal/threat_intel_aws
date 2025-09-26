import json
import boto3
import os
from datetime import datetime

def handler(event, context):
    """
    Lambda function to validate incoming data
    This is a simple example that checks if the data has required fields
    """
    
    print(f"Validator function started at {datetime.now()}")
    print(f"Received event: {json.dumps(event)}")
    
    try:
        # Get S3 bucket from environment
        s3_bucket = os.environ['S3_BUCKET']
        
        # Simulate data validation
        if 'data' not in event:
            raise ValueError("Missing 'data' field in input")
        
        data = event['data']
        
        # Simple validation rules
        if not isinstance(data, dict):
            raise ValueError("Data must be a dictionary")
        
        if 'id' not in data:
            raise ValueError("Data must have an 'id' field")
        
        if 'message' not in data:
            raise ValueError("Data must have a 'message' field")
        
        # Add validation timestamp
        data['validated_at'] = datetime.now().isoformat()
        data['validation_status'] = 'passed'
        
        # Store validated data in S3 (simplified)
        s3_client = boto3.client('s3')
        key = f"validated/{data['id']}.json"
        
        s3_client.put_object(
            Bucket=s3_bucket,
            Key=key,
            Body=json.dumps(data),
            ContentType='application/json'
        )
        
        print(f"Data validated successfully. Stored in S3: {key}")
        
        return {
            'statusCode': 200,
            'body': {
                'message': 'Data validation successful',
                'data': data,
                's3_key': key
            }
        }
        
    except Exception as e:
        print(f"Validation failed: {str(e)}")
        raise e
