# Blockchain Deployment Guide for AWS

## Overview
This guide will help you deploy the blockchain portion of your fraud detection system on AWS. The deployment includes:
1. Smart contract deployment on Sepolia testnet
2. Mempool listener service on AWS EC2
3. Integration with your existing ML API

## Prerequisites

### 1. AWS Account Setup
- AWS Account with EC2 access
- AWS CLI configured
- Key pair for EC2 instance

### 2. Ethereum Development Setup
- Infura account (for RPC endpoints)
- Etherscan account (for contract verification)
- MetaMask wallet with Sepolia testnet ETH

### 3. Environment Variables Needed
Create a `.env` file in the `Dex's` directory with:
```
RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
WSS_PROVIDER=wss://sepolia.infura.io/ws/v3/YOUR_INFURA_PROJECT_ID
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
CONTRACT_OWNER_ADDRESS=0xFd9EbB184C893F3cadc4C134FDCdf4c742E3c838
```

## Step-by-Step Deployment

### Step 1: Deploy Smart Contract

1. **Navigate to blockchain directory:**
   ```bash
   cd "Dex's"
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Compile contracts:**
   ```bash
   npm run compile
   ```

4. **Deploy to Sepolia:**
   ```bash
   npm run deploy
   ```

5. **Save the deployed contract address** - You'll need this for the mempool listener

### Step 2: Deploy Mempool Listener on AWS EC2

1. **Launch EC2 Instance:**
   - Instance Type: t3.medium (recommended)
   - OS: Ubuntu 22.04 LTS
   - Storage: 20GB
   - Security Group: Allow SSH (port 22) and HTTP (port 80)

2. **Connect to EC2 instance:**
   ```bash
   ssh -i your-key.pem ubuntu@your-ec2-ip
   ```

3. **Install Node.js and npm:**
   ```bash
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

4. **Install PM2 for process management:**
   ```bash
   sudo npm install -g pm2
   ```

5. **Clone your project:**
   ```bash
   git clone <your-repo-url>
   cd Dex-s-master/Desktop/Dapp_FraudDetect/mempool-listener
   ```

6. **Install dependencies:**
   ```bash
   npm install
   ```

7. **Create environment file:**
   ```bash
   nano .env
   ```
   Add:
   ```
   WSS_PROVIDER=wss://sepolia.infura.io/ws/v3/YOUR_INFURA_PROJECT_ID
   CONTRACT_ADDRESS=YOUR_DEPLOYED_CONTRACT_ADDRESS
   PRIVATE_KEY=YOUR_PRIVATE_KEY_FOR_CONTRACT_INTERACTION
   ```

8. **Start the mempool listener:**
   ```bash
   pm2 start index.js --name "mempool-listener"
   pm2 save
   pm2 startup
   ```

### Step 3: Update Frontend Configuration

1. **Update your Vercel frontend** with the deployed contract address
2. **Update ABI** if needed
3. **Test the integration**

### Step 4: Monitoring and Maintenance

1. **Monitor logs:**
   ```bash
   pm2 logs mempool-listener
   ```

2. **Restart service if needed:**
   ```bash
   pm2 restart mempool-listener
   ```

3. **Check contract events** on Etherscan

## Security Considerations

1. **Never commit private keys** to version control
2. **Use environment variables** for sensitive data
3. **Regularly update dependencies**
4. **Monitor AWS costs**
5. **Set up CloudWatch alarms** for monitoring

## Troubleshooting

### Common Issues:
1. **Contract deployment fails**: Check RPC URL and private key
2. **Mempool listener stops**: Check WebSocket connection and restart
3. **High gas fees**: Wait for network congestion to reduce
4. **EC2 instance issues**: Check security groups and instance health

### Useful Commands:
```bash
# Check PM2 status
pm2 status

# View logs
pm2 logs

# Restart service
pm2 restart mempool-listener

# Check disk space
df -h

# Check memory usage
free -h
```

## Cost Estimation

- **EC2 t3.medium**: ~$30/month
- **Data transfer**: Minimal for mempool monitoring
- **Sepolia testnet**: Free (testnet)

## Next Steps

1. Deploy to mainnet when ready
2. Set up automated monitoring
3. Implement backup strategies
4. Consider using AWS Lambda for cost optimization
