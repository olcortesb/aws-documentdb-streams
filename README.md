# DocumentDB Streams Demo with Terraform

This project demonstrates how to implement DocumentDB Streams with AWS Lambda using Terraform.

## Architecture

![Architecture](/images/dcdb-1.png)

## How It Works

1. **API Gateway** → **Lambda Writer** → **DocumentDB** (automatically configures streams)
2. **CloudWatch Events** executes **Lambda Stream Processor** every minute
3. **Lambda Stream Processor** connects directly to DocumentDB change stream
4. Processes changes in real-time (insert, update, delete)

## Data Structure

**Database**: `demo_db`  
**Collection**: `users`

**Sample document**:
```json
{
  "_id": ObjectId("..."),
  "user_id": "user_123",
  "name": "John Doe",
  "email": "john@example.com",
  "timestamp": "2024-01-15T10:30:45.123Z",
  "action": "user_created"
}
```

## Deployment

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed (>= 1.0)
- `wget` or `curl` for downloading certificates

### 1. Download updated SSL certificates

```bash
# Download certificate for Lambda Writer
cd lambda/writer
wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -O global-bundle.pem

# Download certificate for Lambda Stream Processor
cd ../stream-processor
wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -O global-bundle.pem

# Return to root directory
cd ../..
```

### 2. Recompile Lambda functions

```bash
# Recompile Lambda Writer
cd lambda/writer && zip -r ../../lambda_writer.zip .

# Recompile Lambda Stream Processor
cd ../stream-processor && zip -r ../../lambda_stream_processor.zip .

# Return to root directory
cd ../..
```

### 3. Deploy infrastructure

```bash
terraform init
terraform apply
```

> **Note:** The SSL certificates and Lambda ZIP files are excluded from version control for security reasons. You must download and compile them locally before deployment.

## Usage

```bash
# Test insertion (automatically enables streams on first execution)
curl -X POST $(terraform output -raw api_gateway_url) \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_456",
    "name": "Jane Smith",
    "email": "jane@example.com"
  }'

# Expected response:
# {"message": "Document inserted successfully", "document_id": "..."}

# View stream processor logs (detected changes)
aws logs tail /aws/lambda/docdb-streams-demo-stream-processor --follow --region us-east-1

# View writer logs
aws logs tail /aws/lambda/docdb-streams-demo-writer --follow --region us-east-1
```

## System Verification

### 1. Insert test document
```bash
curl -X POST $(terraform output -raw api_gateway_url) \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_001",
    "name": "Test User",
    "email": "test@example.com"
  }'
```

### 2. Verify stream processor logs
```bash
aws logs tail /aws/lambda/docdb-streams-demo-stream-processor --since 2m --region us-east-1
```

**Expected output:**
```
Change detected: insert on document 695e5fab9b81562a7ecbe21a
New document: {"_id": "...", "user_id": "test_001", "name": "Test User", ...}
```

## Troubleshooting

### SSL Certificate Error

If you get errors like `[SSL: CERTIFICATE_VERIFY_FAILED]`:

1. **Download updated certificates:**
   ```bash
   cd lambda/writer
   wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -O global-bundle.pem
   
   cd ../stream-processor
   wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -O global-bundle.pem
   ```

2. **Recompile and redeploy:**
   ```bash
   cd lambda/writer && zip -r ../../lambda_writer.zip .
   cd ../stream-processor && zip -r ../../lambda_stream_processor.zip .
   cd ../..
   terraform apply -target=aws_lambda_function.writer -target=aws_lambda_function.stream_processor
   ```

### API Gateway Timeout

If the API returns `"Endpoint request timed out"`:

1. **Check VPC connectivity:** Lambdas must be able to access DocumentDB
2. **Review security groups:** Port 27017 must be open between Lambda and DocumentDB
3. **Check Lambda logs:**
   ```bash
   aws logs tail /aws/lambda/docdb-streams-demo-writer --follow --region us-east-1
   ```

### Error "modifyChangeStreams has not been run"

If the stream processor shows this error:

1. **Insert a document** to enable change streams:
   ```bash
   curl -X POST $(terraform output -raw api_gateway_url) \
     -H "Content-Type: application/json" \
     -d '{"user_id": "init_001", "name": "Init User", "email": "init@example.com"}'
   ```

2. **Verify they were enabled** in the writer logs:
   ```bash
   aws logs tail /aws/lambda/docdb-streams-demo-writer --since 2m --region us-east-1
   ```
   
   Look for: `Change streams enabled for collection`

### Update Lambdas without Terraform

If you need to update Lambda code quickly:

```bash
# Update Lambda Writer
cd lambda/writer && zip -r ../../lambda_writer.zip .
aws lambda update-function-code --function-name docdb-streams-demo-writer --zip-file fileb://../../lambda_writer.zip --region us-east-1

# Update Lambda Stream Processor
cd ../stream-processor && zip -r ../../lambda_stream_processor.zip .
aws lambda update-function-code --function-name docdb-streams-demo-stream-processor --zip-file fileb://../../lambda_stream_processor.zip --region us-east-1
```

## Features

- ✅ **Automatic configuration** of change streams when inserting first document
- ✅ **Real-time processing** (every minute via CloudWatch Events)
- ✅ **Direct connection** to DocumentDB streams with updated SSL certificates
- ✅ **Complete change detection** (insert, update, delete)
- ✅ **Optimized timeout handling** and processing limits
- ✅ **Secure VPC** with private subnets for DocumentDB
- ✅ **Detailed logging** for monitoring and debugging
- ✅ **Fully managed serverless** architecture

## External Connectivity

**DocumentDB is in private VPC** - not directly accessible from the internet.

**Options for external access:**
- **Bastion Host**: EC2 instance in public subnet with MongoDB client
- **VPN**: AWS Site-to-Site VPN or Client VPN
- **SSH Tunnel**: Port forwarding through bastion
- **Session Manager**: Port forwarding without direct SSH

## System Status

✅ **Fully functional and tested:**
- API Gateway receives requests correctly
- Lambda Writer inserts documents and enables change streams
- Lambda Stream Processor detects and processes changes in real-time
- Updated SSL certificates working
- Logs show successful change processing

## Security Considerations

### Excluded Files

For security reasons, the following files are excluded from version control:

- **SSL Certificates** (`*.pem`): Must be downloaded from AWS
- **Lambda Packages** (`*.zip`): Must be compiled locally
- **Terraform State** (`*.tfstate`): Contains sensitive resource information
- **Variables Files** (`*.tfvars`): May contain sensitive configuration

### Required Setup for New Users

If you're cloning this repository, you must:

1. **Download SSL certificates** (see Deployment section)
2. **Compile Lambda packages** (see Deployment section)
3. **Configure AWS credentials** with appropriate permissions:
   - DocumentDB management
   - Lambda function management
   - VPC and networking
   - IAM role creation
   - CloudWatch Events

### AWS Permissions Required

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "docdb:*",
        "lambda:*",
        "apigateway:*",
        "iam:*",
        "ec2:*",
        "events:*",
        "logs:*",
        "secretsmanager:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Cleanup

```bash
terraform destroy
```