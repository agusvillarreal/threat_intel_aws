import json
import boto3
import os
from datetime import datetime

def handler(event, context):
    """
    Lambda function to process validated data
    This is a simple example that transforms the data
    """
    
    print(f"Processor function started at {datetime.now()}")
    print(f"Received event: {json.dumps(event)}")
    
    try:
        # Get S3 bucket from environment
        s3_bucket = os.environ['S3_BUCKET']
        
        # Get data from previous step
        if 'body' in event and 'data' in event['body']:
            data = event['body']['data']
        else:
            raise ValueError("No data received from previous step")
        
        # Simulate data processing
        processed_data = {
            'id': data['id'],
            'original_message': data['message'],
            'processed_message': data['message'].upper(),  # Simple transformation
            'processed_at': datetime.now().isoformat(),
            'processing_status': 'completed',
            'word_count': len(data['message'].split()),
            'character_count': len(data['message'])
        }
        
        # Store processed data in S3
        s3_client = boto3.client('s3')
        key = f"processed/{data['id']}.json"
        
        s3_client.put_object(
            Bucket=s3_bucket,
            Key=key,
            Body=json.dumps(processed_data),
            ContentType='application/json'
        )
        
        print(f"Data processed successfully. Stored in S3: {key}")
        
        return {
            'statusCode': 200,
            'body': {
                'message': 'Data processing successful',
                'data': processed_data,
                's3_key': key
            }
        }
        
    except Exception as e:
        print(f"Processing failed: {str(e)}")
        raise e

