# 🔒 File Security System

A comprehensive, production-ready AWS infrastructure for secure file uploads with automatic malware detection and quarantine capabilities.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client App    │    │  API Gateway    │    │  Presign URL    │
│                 │───▶│                 │───▶│    Lambda       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   DynamoDB      │◀───│  File Processor │◀───│   S3 Upload     │
│   File Tracking │    │    Lambda       │    │    Bucket       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │  S3 Malware     │
                                              │  Quarantine     │
                                              │    Bucket       │
                                              └─────────────────┘
```

## 📁 Project Structure

```
s3-scanning-tf/
├── 📄 providers.tf              # AWS provider configuration
├── 📄 variables.tf              # Input variables and validation
├── 📄 main.tf                   # Main orchestrator and locals
├── 📄 s3.tf                     # S3 bucket configurations
├── 📄 dynamodb.tf               # DynamoDB table setup
├── 📄 iam.tf                    # IAM roles and policies
├── 📄 lambda_functions.tf       # Lambda functions and triggers
├── 📄 api_gateway.tf            # API Gateway configuration
├── 📄 outputs.tf                # Output values
├── 📄 terraform.tfvars.example  # Example configuration
├── 📁 lambda/
│   ├── 📄 presign_url.py        # Presign URL generator
│   ├── 📄 file_processor.py     # File processing and scanning
│   └── 📄 requirements.txt      # Python dependencies
├── 📄 README.md                 # This file
└── 📄 DEPLOYMENT.md             # Deployment guide
```

## 🚀 Features

### ✅ **Core Functionality**
- **Secure File Uploads**: Presigned URLs for direct S3 uploads
- **File Validation**: Extension and size validation
- **Malware Detection**: Integration with AWS GuardDuty
- **Automatic Quarantine**: Malicious files moved to isolated bucket
- **Status Tracking**: Complete file lifecycle tracking in DynamoDB

### ✅ **Security Features**
- **Server-side Encryption**: AES256 encryption for all S3 objects
- **Public Access Block**: All S3 buckets are private
- **Versioning**: File versioning enabled for audit trails
- **IAM Least Privilege**: Minimal required permissions
- **CORS Support**: Cross-origin resource sharing headers

### ✅ **Monitoring & Observability**
- **CloudWatch Logs**: Comprehensive logging for all Lambda functions
- **Structured Logging**: JSON-formatted logs with correlation IDs
- **Error Handling**: Graceful error handling and status updates
- **Audit Trail**: Complete file processing history

### ✅ **Scalability & Reliability**
- **Serverless Architecture**: Auto-scaling Lambda functions
- **Pay-per-use**: DynamoDB on-demand billing
- **High Availability**: Multi-AZ deployment
- **Fault Tolerance**: Retry mechanisms and error recovery

## 🔧 Configuration

### **Environment Variables**

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-east-1` |
| `project_name` | Project name for resource tagging | `file-security-system` |
| `environment` | Environment (dev/staging/production) | `production` |
| `s3_bucket_name` | Main upload bucket name | `file-upload-bucket` |
| `dynamodb_table_name` | File tracking table name | `file-tracking-table` |
| `lambda_runtime` | Python runtime version | `python3.12` |
| `lambda_timeout` | Lambda function timeout (seconds) | `30` |
| `lambda_memory_size` | Lambda memory allocation (MB) | `128` |
| `allowed_file_extensions` | List of allowed file extensions | `[".txt", ".pdf", ".doc", ".docx", ".jpg", ".png", ".gif"]` |
| `max_file_size_mb` | Maximum file size (MB) | `100` |
| `enable_encryption` | Enable S3 server-side encryption | `true` |
| `enable_versioning` | Enable S3 versioning | `true` |
| `enable_cloudwatch_logs` | Enable CloudWatch logging | `true` |
| `log_retention_days` | CloudWatch log retention (days) | `30` |

### **File Status Flow**

```
UPLOADED → SCANNING → CLEAN (if clean)
                ↓
            THREATS_FOUND → MOVED_TO_MALWARE_BUCKET
                ↓
            MOVE_FAILED (if move fails)
                ↓
            FAILED (if polling times out)
```

## 🛠️ Installation & Deployment

### **Prerequisites**
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Python 3.9+ (for local testing)

### **Quick Start**

1. **Clone and Configure**
   ```bash
   git clone <repository-url>
   cd s3-scanning-tf
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Plan Deployment**
   ```bash
   terraform plan
   ```

4. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

5. **Get Outputs**
   ```bash
   terraform output
   ```

## 📡 API Usage

### **Generate Presign URL**

```bash
curl -X GET "https://<api-gateway-url>/presign?filename=document.pdf&content_type=application/pdf"
```

**Response:**
```json
{
  "url": "https://bucket.s3.amazonaws.com/document.pdf?...",
  "fileId": "550e8400-e29b-41d4-a716-446655440000",
  "filename": "document.pdf",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "expiresIn": 3600,
  "bucket": "file-upload-bucket",
  "contentType": "application/pdf"
}
```

### **Upload File**

```bash
curl -X PUT -T "document.pdf" "https://bucket.s3.amazonaws.com/document.pdf?..."
```

## 🔍 Monitoring & Troubleshooting

### **CloudWatch Logs**
- **Presign URL Lambda**: `/aws/lambda/<project>-<env>-presign-url`
- **File Processor Lambda**: `/aws/lambda/<project>-<env>-file-processor`

### **DynamoDB Queries**

**Get file by ID:**
```bash
aws dynamodb get-item \
  --table-name file-tracking-table \
  --key '{"fileId": {"S": "550e8400-e29b-41d4-a716-446655440000"}}'
```

**Query by status:**
```bash
aws dynamodb query \
  --table-name file-tracking-table \
  --index-name status-index \
  --key-condition-expression "status = :status" \
  --expression-attribute-values '{":status": {"S": "CLEAN"}}'
```

### **Common Issues**

1. **GuardDuty Not Enabled**: Manually enable GuardDuty in AWS Console
2. **S3 Bucket Name Conflict**: Choose a globally unique bucket name
3. **IAM Permissions**: Ensure AWS credentials have sufficient permissions
4. **Lambda Timeout**: Increase `lambda_timeout` for large files

## 🔒 Security Considerations

### **Data Protection**
- All data encrypted at rest and in transit
- S3 buckets have public access blocked
- DynamoDB uses server-side encryption
- Lambda environment variables are encrypted

### **Access Control**
- IAM roles follow least privilege principle
- API Gateway has CORS configured
- S3 bucket policies enforce encryption
- DynamoDB access controlled via IAM

### **Compliance**
- Audit trails via CloudWatch logs
- File versioning for compliance
- Complete file lifecycle tracking
- Malware quarantine isolation

## 💰 Cost Optimization

### **Cost Factors**
- **Lambda**: Pay per request and execution time
- **DynamoDB**: Pay per request (on-demand billing)
- **S3**: Pay per GB stored and requests
- **API Gateway**: Pay per request
- **CloudWatch**: Pay per GB of logs

### **Optimization Tips**
- Use appropriate Lambda memory allocation
- Set CloudWatch log retention periods
- Monitor DynamoDB read/write capacity
- Clean up old S3 versions periodically
- Use S3 lifecycle policies for cost management

## 🚀 Future Enhancements

### **Planned Features**
- [ ] Webhook notifications for file status changes
- [ ] File metadata extraction and indexing
- [ ] Advanced malware scanning with multiple engines
- [ ] File processing pipeline with multiple stages
- [ ] Real-time dashboard for file monitoring
- [ ] Integration with external security services
- [ ] Automated backup and disaster recovery
- [ ] Multi-region deployment support

### **Performance Improvements**
- [ ] Lambda function optimization
- [ ] DynamoDB query optimization
- [ ] S3 transfer acceleration
- [ ] CDN integration for file delivery
- [ ] Caching layer for frequently accessed data

## 📞 Support

For issues and questions:
1. Check CloudWatch logs for error details
2. Review DynamoDB table for file status
3. Verify IAM permissions and roles
4. Check S3 bucket configurations
5. Ensure GuardDuty is properly configured

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Built with ❤️ using AWS, Terraform, and Python**