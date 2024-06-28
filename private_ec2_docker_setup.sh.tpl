#!/bin/bash
# Log everything
exec > /var/log/user-data.log 2>&1

# Update packages and install Docker
sudo yum update -y
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

# Install the CloudWatch agent
sudo yum install amazon-cloudwatch-agent

# Install jq
sudo dnf install -y jq

# # Get AWS Account ID from instance metadata
# AWS_ACCOUNT_ID=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .accountId)

# Fetch the IMDSv2 token
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

if [ -z "$TOKEN" ]; then
  echo "Failed to retrieve IMDSv2 token"
  exit 1
fi

echo "Token retrieved successfully: $TOKEN"

# Get AWS Account ID using the token and log the output
echo "Retrieving AWS Account ID..."
curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/dynamic/instance-identity/document > /var/log/instance-identity-document.json
AWS_ACCOUNT_ID=$(jq -r .accountId /var/log/instance-identity-document.json)

if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "Failed to retrieve AWS Account ID"
  cat /var/log/instance-identity-document.json
  exit 1
fi

echo "AWS Account ID: $AWS_ACCOUNT_ID"

# Log in to AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

if [ $? -ne 0 ]; then
  echo "Failed to log in to AWS ECR"
  echo $LOGIN_COMMAND
  exit 1
fi

# Pull Docker images from ECR
docker pull $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cwc-ecr:latest

# Run Docker containers
docker run -d -p 80:3000 $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/cwc-ecr:latest
