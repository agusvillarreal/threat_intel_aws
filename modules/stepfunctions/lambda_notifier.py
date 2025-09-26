import json
import boto3
import os
from datetime import datetime

def handler(event, context):
    """
    Lambda function to send notifications about processed data
    This is a simple example that logs the completion
    """
    
    print(f"Notifier function started at {datetime.now()}")
    print(f"Received event: {json.dumps(event)}")
    
    try:
        # Get S3 bucket from environment
        s3_bucket = os.environ['S3_BUCKET']
        
        # Get data from previous step
        if 'body' in event and 'data' in event['body']:
            data = event['body']['data']
        else:
            raise ValueError("No data received from previous step")
        
        # Create notification message
        notification = {
            'id': data['id'],
            'message': f"Data processing completed for ID: {data['id']}",
            'original_message': data['original_message'],
            'processed_message': data['processed_message'],
            'word_count': data['word_count'],
            'character_count': data['character_count'],
            'completed_at': datetime.now().isoformat(),
            'status': 'success'
        }
        
        # Store notification in S3
        s3_client = boto3.client('s3')
        key = f"notifications/{data['id']}.json"
        
        s3_client.put_object(
            Bucket=s3_bucket,
            Key=key,
            Body=json.dumps(notification),
            ContentType='application/json'
        )
        
        print(f"Notification sent successfully. Stored in S3: {key}")
        
        # In a real scenario, you might send emails, SMS, or push notifications here
        # For this example, we'll just log the notification
        
        return {
            'statusCode': 200,
            'body': {
                'message': 'Notification sent successfully',
                'notification': notification,
                's3_key': key
            }
        }
        
    except Exception as e:
        print(f"Notification failed: {str(e)}")
        raise e

