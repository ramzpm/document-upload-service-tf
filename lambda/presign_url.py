"""
Presign URL Lambda Function
Generates secure presigned URLs for direct S3 uploads with file validation.
"""

import json
import boto3
import os
import uuid
from datetime import datetime, timedelta
from urllib.parse import urlparse

def lambda_handler(event, context):
    """
    Main Lambda handler for generating presigned URLs.
    
    Expected query parameters:
    - filename: Name of the file to upload
    - content_type: MIME type of the file (optional)
    
    Returns:
    - url: Presigned URL for direct S3 upload
    - fileId: Unique identifier for the file
    - filename: Original filename
    - timestamp: ISO timestamp of request
    """
    try:
        # Get environment variables
        bucket_name = os.environ.get('UPLOAD_BUCKET_NAME')
        allowed_extensions = os.environ.get('ALLOWED_EXTENSIONS', '').split(',')
        max_file_size_mb = int(os.environ.get('MAX_FILE_SIZE_MB', '100'))
        
        # Parse query parameters
        query_params = event.get('queryStringParameters', {}) or {}
        filename = query_params.get('filename')
        content_type = query_params.get('content_type', 'application/octet-stream')
        
        # Validate required parameters
        if not filename:
            return create_error_response(400, "filename parameter is required")
        
        # Validate file extension
        file_extension = os.path.splitext(filename)[1].lower()
        if file_extension not in allowed_extensions:
            return create_error_response(
                400, 
                f"File extension {file_extension} not allowed. Allowed extensions: {', '.join(allowed_extensions)}"
            )
        
        # Generate unique fileId
        file_id = str(uuid.uuid4())
        
        # Create S3 client
        s3_client = boto3.client('s3')
        
        # Generate presigned URL
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket_name,
                'Key': filename,
                'ContentType': content_type,
                'ServerSideEncryption': 'AES256'
            },
            ExpiresIn=3600  # URL expires in 1 hour
        )
        
        # Create success response
        response_data = {
            'url': presigned_url,
            'fileId': file_id,
            'filename': filename,
            'timestamp': datetime.utcnow().isoformat(),
            'expiresIn': 3600,
            'bucket': bucket_name,
            'contentType': content_type
        }
        
        return create_success_response(response_data)
        
    except Exception as e:
        print(f"Error generating presigned URL: {str(e)}")
        return create_error_response(500, f"Internal server error: {str(e)}")

def create_success_response(data):
    """Create a standardized success response."""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
        },
        'body': json.dumps(data, indent=2)
    }

def create_error_response(status_code, message):
    """Create a standardized error response."""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
        },
        'body': json.dumps({
            'error': message,
            'timestamp': datetime.utcnow().isoformat()
        }, indent=2)
    }
