#!/bin/bash

# AWS Deployment Script for Mempool Listener
# This script automates the deployment of the mempool listener on AWS EC2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
INSTANCE_TYPE="t3.medium"
AMI_ID="ami-0c02fb55956c7d316" # Ubuntu 22.04 LTS in us-east-1
KEY_NAME="your-key-pair-name"
SECURITY_GROUP_NAME="mempool-listener-sg"
REGION="us-east-1"

echo -e "${GREEN}Starting AWS deployment for mempool listener...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "${RED}Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables${NC}"
    exit 1
fi

# Create security group
echo -e "${YELLOW}Creating security group...${NC}"
aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for mempool listener" \
    --region $REGION || echo "Security group already exists"

# Add rules to security group
echo -e "${YELLOW}Adding security group rules...${NC}"
aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_NAME \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0 \
    --region $REGION || echo "SSH rule already exists"

aws ec2 authorize-security-group-ingress \
    --group-name $SECURITY_GROUP_NAME \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $REGION || echo "HTTP rule already exists"

# Launch EC2 instance
echo -e "${YELLOW}Launching EC2 instance...${NC}"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP_NAME \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

echo -e "${GREEN}Instance launched with ID: $INSTANCE_ID${NC}"

# Wait for instance to be running
echo -e "${YELLOW}Waiting for instance to be running...${NC}"
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --region $REGION \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo -e "${GREEN}Instance is running at: $PUBLIC_IP${NC}"

# Wait for SSH to be available
echo -e "${YELLOW}Waiting for SSH to be available...${NC}"
until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ~/.ssh/$KEY_NAME.pem ubuntu@$PUBLIC_IP "echo 'SSH is ready'" 2>/dev/null; do
    echo "Waiting for SSH..."
    sleep 10
done

# Copy deployment files
echo -e "${YELLOW}Copying deployment files...${NC}"
scp -i ~/.ssh/$KEY_NAME.pem -r mempool-listener/ ubuntu@$PUBLIC_IP:~/

# Execute deployment commands
echo -e "${YELLOW}Installing dependencies and starting service...${NC}"
ssh -i ~/.ssh/$KEY_NAME.pem ubuntu@$PUBLIC_IP << 'EOF'
    # Update system
    sudo apt-get update
    
    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    # Install PM2
    sudo npm install -g pm2
    
    # Navigate to mempool listener directory
    cd mempool-listener
    
    # Install dependencies
    npm install
    
    # Create .env file (you'll need to edit this manually)
    cat > .env << 'ENVEOF'
WSS_PROVIDER=wss://sepolia.infura.io/ws/v3/YOUR_INFURA_PROJECT_ID
RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
CONTRACT_ADDRESS=YOUR_DEPLOYED_CONTRACT_ADDRESS
PRIVATE_KEY=YOUR_PRIVATE_KEY_FOR_CONTRACT_INTERACTION
ENVEOF
    
    # Start the service with PM2
    pm2 start index.js --name "mempool-listener"
    pm2 save
    pm2 startup
    
    echo "Deployment completed!"
    echo "To view logs: pm2 logs mempool-listener"
    echo "To restart: pm2 restart mempool-listener"
    echo "To stop: pm2 stop mempool-listener"
EOF

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${YELLOW}Instance IP: $PUBLIC_IP${NC}"
echo -e "${YELLOW}Instance ID: $INSTANCE_ID${NC}"
echo -e "${YELLOW}Don't forget to:${NC}"
echo -e "${YELLOW}1. Update the .env file with your actual credentials${NC}"
echo -e "${YELLOW}2. Set up the deployed contract address${NC}"
echo -e "${YELLOW}3. Configure the contract owner to add this address as a reporter${NC}"
