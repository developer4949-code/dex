#!/bin/bash

# Quick Deployment Script for Fraud Detection System
# This script guides you through the entire deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Fraud Detection System Deployment${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt for input
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\${input:-$default}"
    else
        read -p "$prompt: " input
        eval "$var_name=\$input"
    fi
}

# Function to create .env file
create_env_file() {
    local env_file="$1"
    cat > "$env_file" << EOF
# Ethereum Network Configuration
RPC_URL=https://sepolia.infura.io/v3/$INFURA_PROJECT_ID
WSS_PROVIDER=wss://sepolia.infura.io/ws/v3/$INFURA_PROJECT_ID

# Deployment Account
PRIVATE_KEY=$PRIVATE_KEY

# Etherscan API Key (for contract verification)
ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY

# Contract Owner Address
CONTRACT_OWNER_ADDRESS=$CONTRACT_OWNER_ADDRESS
EOF
}

echo -e "${YELLOW}Step 1: Prerequisites Check${NC}"
echo ""

# Check Node.js
if ! command_exists node; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js 18+ first.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Node.js is installed ($(node --version))${NC}"
fi

# Check npm
if ! command_exists npm; then
    echo -e "${RED}❌ npm is not installed.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ npm is installed ($(npm --version))${NC}"
fi

# Check AWS CLI
if ! command_exists aws; then
    echo -e "${YELLOW}⚠️  AWS CLI is not installed. You'll need to install it for AWS deployment.${NC}"
    AWS_CLI_INSTALLED=false
else
    echo -e "${GREEN}✅ AWS CLI is installed${NC}"
    AWS_CLI_INSTALLED=true
fi

echo ""
echo -e "${YELLOW}Step 2: Configuration Setup${NC}"
echo ""

# Get configuration details
prompt_input "Enter your Infura Project ID" "INFURA_PROJECT_ID"
prompt_input "Enter your private key (without 0x)" "PRIVATE_KEY"
prompt_input "Enter your Etherscan API key" "ETHERSCAN_API_KEY"
prompt_input "Enter contract owner address" "CONTRACT_OWNER_ADDRESS" "0xFd9EbB184C893F3cadc4C134FDCdf4c742E3c838"

echo ""
echo -e "${YELLOW}Step 3: Smart Contract Deployment${NC}"
echo ""

# Navigate to blockchain directory
cd "Dex's"

# Create .env file
echo "Creating .env file..."
create_env_file ".env"
echo -e "${GREEN}✅ .env file created${NC}"

# Install dependencies
echo "Installing dependencies..."
npm install
echo -e "${GREEN}✅ Dependencies installed${NC}"

# Compile contracts
echo "Compiling contracts..."
npm run compile
echo -e "${GREEN}✅ Contracts compiled${NC}"

# Deploy contract
echo "Deploying contract to Sepolia..."
npx hardhat run scripts/deploy-with-verification.js --network sepolia

# Get contract address from deployment info
if [ -f "deployment-info.json" ]; then
    CONTRACT_ADDRESS=$(node -e "console.log(JSON.parse(require('fs').readFileSync('deployment-info.json')).address)")
    echo -e "${GREEN}✅ Contract deployed at: $CONTRACT_ADDRESS${NC}"
else
    echo -e "${RED}❌ Contract deployment failed or deployment-info.json not found${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 4: AWS Deployment${NC}"
echo ""

if [ "$AWS_CLI_INSTALLED" = true ]; then
    echo "AWS CLI is available. Do you want to deploy to AWS now? (y/n)"
    read -p "Deploy to AWS? " deploy_aws
    
    if [[ $deploy_aws =~ ^[Yy]$ ]]; then
        # Get AWS configuration
        prompt_input "Enter your AWS key pair name" "AWS_KEY_PAIR"
        prompt_input "Enter your AWS region" "AWS_REGION" "us-east-1"
        
        # Update AWS deployment script
        sed -i "s/KEY_NAME=\"your-key-pair-name\"/KEY_NAME=\"$AWS_KEY_PAIR\"/" ../aws-deploy.sh
        sed -i "s/REGION=\"us-east-1\"/REGION=\"$AWS_REGION\"/" ../aws-deploy.sh
        
        # Make script executable
        chmod +x ../aws-deploy.sh
        
        echo "Starting AWS deployment..."
        cd ..
        ./aws-deploy.sh
        
        echo ""
        echo -e "${GREEN}✅ AWS deployment completed!${NC}"
    else
        echo -e "${YELLOW}⚠️  Skipping AWS deployment. You can run it manually later.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  AWS CLI not available. Please install it and run aws-deploy.sh manually.${NC}"
fi

echo ""
echo -e "${YELLOW}Step 5: Configuration Summary${NC}"
echo ""

echo -e "${BLUE}Deployment Information:${NC}"
echo "Contract Address: $CONTRACT_ADDRESS"
echo "Network: Sepolia"
echo "Owner Address: $CONTRACT_OWNER_ADDRESS"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo "1. Update your frontend with the contract address: $CONTRACT_ADDRESS"
echo "2. If not deployed to AWS, run: ./aws-deploy.sh"
echo "3. Configure the mempool listener with the contract address"
echo "4. Set up reporter permissions in the contract"
echo "5. Test the complete system"
echo ""

echo -e "${GREEN}🎉 Deployment process completed!${NC}"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "- Keep your private keys secure"
echo "- Monitor your AWS costs"
echo "- Test the system thoroughly"
echo "- Set up monitoring and alerts"
