import json
import boto3
import os
import uuid
from datetime import datetime

def lambda_handler(event, context):
    try:
        bucket_name = os.environ.get('UPLOAD_BUCKET_NAME')
        allowed_extensions = os.environ.get('ALLOWED_EXTENSIONS', '').split(',')
        
        # Query params from API Gateway
        query_params = event.get('queryStringParameters', {}) or {}
        filename = query_params.get('filename')
        content_type = query_params.get('content_type', 'application/octet-stream')

        if not filename:
            return create_error_response(400, "filename parameter is required")

        # Validate file extension
        file_extension = os.path.splitext(filename)[1].lower()
        if allowed_extensions and file_extension not in allowed_extensions:
            return create_error_response(
                400,
                f"File extension {file_extension} not allowed. Allowed: {', '.join(allowed_extensions)}"
            )

        # Generate fileId and embed it in key
        file_id = str(uuid.uuid4())
        s3_key = f"uploads/{file_id}_{filename}"

        s3_client = boto3.client('s3')
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket_name,
                'Key': s3_key,
                'ContentType': content_type,
                'ServerSideEncryption': 'AES256'
            },
            ExpiresIn=3600
        )

        response_data = {
            'url': presigned_url,
            'fileId': file_id,
            'filename': filename,
            's3Key': s3_key,
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
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(data, indent=2)
    }


def create_error_response(status_code, message):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'error': message,
            'timestamp': datetime.utcnow().isoformat()
        }, indent=2)
    }
