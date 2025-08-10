"""
File Processor Lambda Function
Processes uploaded files, tracks them in DynamoDB, and manages malware scanning workflow.
"""

import json
import boto3
import os
import time
from datetime import datetime
import uuid

def lambda_handler(event, context):
    """
    Main Lambda handler for processing S3 file uploads.
    
    Processes S3 ObjectCreated events and:
    1. Records file metadata in DynamoDB
    2. Polls for GuardDuty scanning tags
    3. Moves malicious files to quarantine bucket
    4. Updates file status throughout the process
    """
    try:
        # Initialize AWS clients
        s3_client = boto3.client('s3')
        dynamodb = boto3.resource('dynamodb')
        
        # Get environment variables
        table_name = os.environ['DYNAMODB_TABLE_NAME']
        upload_bucket = os.environ['UPLOAD_BUCKET_NAME']
        malware_bucket = os.environ['MALWARE_BUCKET_NAME']
        table = dynamodb.Table(table_name)
        
        # Process S3 event
        for record in event['Records']:
            # Extract S3 information
            s3_bucket = record['s3']['bucket']['name']
            s3_key = record['s3']['object']['key']
            s3_size = record['s3']['object']['size']
            s3_event_time = record['eventTime']
            
            # Generate unique fileId
            file_id = str(uuid.uuid4())
            
            # Determine file type from extension
            file_extension = os.path.splitext(s3_key)[1].lower()
            file_type = file_extension if file_extension else 'unknown'
            
            # Create item for DynamoDB
            item = {
                'fileId': file_id,
                'filename': s3_key,
                'bucket': s3_bucket,
                'fileSize': s3_size,
                'fileType': file_type,
                'uploadedStatus': 'UPLOADED',  # Initial status
                'createdTimestamp': s3_event_time,
                'updatedTimestamp': s3_event_time,
                'uploadedBy': 's3_trigger',
                'metadata': {
                    'source': 's3_upload',
                    'event_type': record['eventName']
                }
            }
            
            # Insert into DynamoDB
            table.put_item(Item=item)
            
            print(f"Successfully inserted file record: {file_id} for file: {s3_key}")
            
            # Start polling for GuardDuty tags
            poll_guardduty_tags(s3_client, s3_bucket, s3_key, file_id, table, malware_bucket)
        
        return create_success_response({
            'message': 'Successfully processed S3 upload event',
            'processed_files': len(event['Records'])
        })
        
    except Exception as e:
        print(f"Error processing S3 event: {str(e)}")
        return create_error_response(500, f"Internal server error: {str(e)}")

def poll_guardduty_tags(s3_client, bucket, key, file_id, table, malware_bucket):
    """
    Poll for GuardDuty tags every 1 second for 10 times.
    
    Args:
        s3_client: Boto3 S3 client
        bucket: S3 bucket name
        key: S3 object key
        file_id: Unique file identifier
        table: DynamoDB table object
        malware_bucket: Malware quarantine bucket name
    """
    max_attempts = 10
    poll_interval = 1  # 1 second
    
    print(f"Starting to poll for GuardDuty tags for file: {key}")
    
    for attempt in range(max_attempts):
        try:
            print(f"Polling attempt {attempt + 1}/{max_attempts}")
            
            # Get object tags
            response = s3_client.get_object_tagging(
                Bucket=bucket,
                Key=key
            )
            
            # Check for GuardDutyMalwareScanStatus tag
            guardduty_status = None
            for tag in response.get('TagSet', []):
                if tag['Key'] == 'GuardDutyMalwareScanStatus':
                    guardduty_status = tag['Value']
                    break
            
            if guardduty_status:
                print(f"Found GuardDuty tag: {guardduty_status}")
                
                # Map GuardDuty status to our status values
                if guardduty_status == 'CLEAN':
                    update_status(table, file_id, 'CLEAN')
                elif guardduty_status == 'THREATS_FOUND':
                    update_status(table, file_id, 'THREATS_FOUND')
                    # Move object to malware bucket
                    move_to_malware_bucket(s3_client, bucket, key, file_id, table, malware_bucket)
                else:
                    # For any other GuardDuty status, use it as is
                    update_status(table, file_id, guardduty_status)
                
                return
            else:
                print(f"No GuardDuty tag found on attempt {attempt + 1}")
                
                # Update status to indicate polling is in progress
                if attempt == 0:
                    update_status(table, file_id, 'SCANNING')
                
        except Exception as e:
            print(f"Error polling for tags on attempt {attempt + 1}: {str(e)}")
        
        # Wait before next attempt (except on last attempt)
        if attempt < max_attempts - 1:
            time.sleep(poll_interval)
    
    # If no tag found after all attempts, set status to FAILED
    print(f"No GuardDuty tag found after {max_attempts} attempts")
    update_status(table, file_id, 'FAILED')

def update_status(table, file_id, uploadedStatus):
    """
    Update status in DynamoDB.
    
    Args:
        table: DynamoDB table object
        file_id: Unique file identifier
        uploadedStatus: New status value
    """
    try:
        table.update_item(
            Key={'fileId': file_id},
            UpdateExpression='SET uploadedStatus = :uploadedStatus, updatedTimestamp = :timestamp',
            ExpressionAttributeValues={
                ':uploadedStatus': uploadedStatus,
                ':timestamp': datetime.utcnow().isoformat()
            }
        )
        print(f"Updated uploadedStatus for {file_id}: {uploadedStatus}")
    except Exception as e:
        print(f"Error updating status: {str(e)}")

def move_to_malware_bucket(s3_client, source_bucket, source_key, file_id, table, malware_bucket):
    """
    Move object from upload bucket to malware bucket.
    
    Args:
        s3_client: Boto3 S3 client
        source_bucket: Source S3 bucket name
        source_key: Source S3 object key
        file_id: Unique file identifier
        table: DynamoDB table object
        malware_bucket: Malware quarantine bucket name
    """
    try:
        print(f"Moving {source_key} from {source_bucket} to {malware_bucket}")
        
        # Copy object to malware bucket
        copy_source = {
            'Bucket': source_bucket,
            'Key': source_key
        }
        
        s3_client.copy_object(
            CopySource=copy_source,
            Bucket=malware_bucket,
            Key=source_key
        )
        
        # Delete object from original bucket
        s3_client.delete_object(
            Bucket=source_bucket,
            Key=source_key
        )
        
         # Update DynamoDB with new bucket location
        table.update_item(
            Key={'fileId': file_id},
            UpdateExpression='SET #bucketName = :bucket, uploadedStatus = :status, updatedTimestamp = :timestamp',
            ExpressionAttributeNames={
                '#bucketName': 'bucket'
            },
            ExpressionAttributeValues={
                ':bucket': malware_bucket,
                ':status': 'MOVED_TO_MALWARE_BUCKET',
                ':timestamp': datetime.utcnow().isoformat()
            }
        )
        
        print(f"Successfully moved {source_key} to malware bucket")

        # Send SES notification email
        send_ses_email(
            recipient=os.environ['SES_RECIPIENT_EMAIL'],  # Set in Lambda ENV
            subject="⚠️ Malware File Detected & Moved",
            body_text=(
                f"A potentially malicious file has been detected and moved.\n\n"
                f"File ID: {file_id}\n"
                f"File Name: {source_key}\n"
                f"Original Bucket: {source_bucket}\n"
                f"Malware Bucket: {malware_bucket}\n"
                f"Time: {datetime.utcnow().isoformat()}\n"
            )
        )
        
    except Exception as e:
        print(f"Error moving object to malware bucket: {str(e)}")
        # Update status to indicate move failed
        update_status(table, file_id, 'MOVE_FAILED')

def create_success_response(data):
    """Create a standardized success response."""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps(data, indent=2)
    }

def create_error_response(status_code, message):
    """Create a standardized error response."""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'error': message,
            'timestamp': datetime.utcnow().isoformat()
        }, indent=2)
    } 


def send_ses_email(recipient, subject, body_text, body_html=None):
    """
    Send email using Amazon SES.
    """
    ses_client = boto3.client('ses')
    CHARSET = "UTF-8"

    try:
        # SendMail request
        response = ses_client.send_email(
            Source=os.environ['SES_SENDER_EMAIL'],  # Verified SES sender
            Destination={
                'ToAddresses': [recipient]
            },
            Message={
                'Subject': {
                    'Data': subject,
                    'Charset': CHARSET
                },
                'Body': {
                    'Text': {
                        'Data': body_text,
                        'Charset': CHARSET
                    },
                    'Html': {
                        'Data': body_html or f"<pre>{body_text}</pre>",
                        'Charset': CHARSET
                    }
                }
            }
        )
        print(f"Email sent! Message ID: {response['MessageId']}")
    except Exception as e:
        print(f"Error sending email via SES: {str(e)}")
