# Fraud Detection System - Blockchain Deployment Guide

## 🎯 Overview

This guide will help you deploy the blockchain portion of your fraud detection system. Your ML API is already hosted and working, so we'll focus on deploying:

1. **Smart Contract** (FraudLogger) on Sepolia testnet
2. **Mempool Listener** on AWS EC2
3. **Integration** with your existing ML API and Vercel frontend

## 📋 Prerequisites

### Required Accounts & Services
- [ ] **Infura Account** - For Ethereum RPC endpoints
- [ ] **Etherscan Account** - For contract verification
- [ ] **AWS Account** - For hosting mempool listener
- [ ] **MetaMask Wallet** - With Sepolia testnet ETH
- [ ] **GitHub Account** - For code repository

### Required Software
- [ ] **Node.js 18+** - For running the blockchain code
- [ ] **AWS CLI** - For AWS deployment automation
- [ ] **Git** - For version control

## 🚀 Quick Start (Recommended)

### Option 1: Automated Deployment (Linux/Mac)
```bash
# Make script executable and run
chmod +x quick-deploy.sh
./quick-deploy.sh
```

### Option 2: Manual Step-by-Step Deployment

## 📝 Step-by-Step Manual Deployment

### Step 1: Smart Contract Deployment

#### 1.1 Navigate to Blockchain Directory
```bash
cd "Dex's"
```

#### 1.2 Install Dependencies
```bash
npm install
```

#### 1.3 Create Environment File
Create a `.env` file in the `Dex's` directory:
```env
RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
WSS_PROVIDER=wss://sepolia.infura.io/ws/v3/YOUR_INFURA_PROJECT_ID
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
```

#### 1.4 Compile Contracts
```bash
npm run compile
```

#### 1.5 Deploy to Sepolia
```bash
npx hardhat run scripts/deploy-with-verification.js --network sepolia
```

#### 1.6 Save Contract Information
- Copy the deployed contract address
- Save the `deployment-info.json` file

### Step 2: AWS Deployment

#### 2.1 Prepare AWS Environment
```bash
# Install AWS CLI (if not already installed)
# Configure AWS credentials
aws configure
```

#### 2.2 Update Deployment Script
Edit `aws-deploy.sh` and update:
- `KEY_NAME` with your AWS key pair name
- `REGION` with your preferred AWS region

#### 2.3 Run AWS Deployment
```bash
chmod +x aws-deploy.sh
./aws-deploy.sh
```

#### 2.4 Configure Mempool Listener
SSH into your EC2 instance and update the `.env` file:
```env
WSS_PROVIDER=wss://sepolia.infura.io/ws/v3/YOUR_INFURA_PROJECT_ID
RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
CONTRACT_ADDRESS=YOUR_DEPLOYED_CONTRACT_ADDRESS
PRIVATE_KEY=YOUR_PRIVATE_KEY_FOR_CONTRACT_INTERACTION
```

#### 2.5 Start the Service
```bash
pm2 start mempool-listener
pm2 save
pm2 startup
```

### Step 3: Contract Configuration

#### 3.1 Set Reporter Permissions
Call the `setReporter` function on your deployed contract to add the mempool listener's address as a reporter.

#### 3.2 Test the Integration
Send a test transaction on Sepolia and verify that:
- Mempool listener detects the transaction
- ML API processes the transaction
- Contract logs the fraud event (if detected)

### Step 4: Frontend Integration

#### 4.1 Update Vercel Frontend
- Update the contract address in your frontend code
- Update the ABI if needed
- Redeploy on Vercel

#### 4.2 Test End-to-End
- Test frontend connection to contract
- Verify event display
- Test user interactions

## 🔧 Configuration Details

### Smart Contract (FraudLogger.sol)
- **Purpose**: Logs fraud detection events on the blockchain
- **Network**: Sepolia testnet
- **Owner**: Address that can add/remove reporters
- **Reporters**: Addresses authorized to log fraud events

### Mempool Listener (index.js)
- **Purpose**: Monitors Ethereum mempool for transactions
- **Integration**: Calls your ML API for fraud prediction
- **Output**: Logs high-risk transactions to the smart contract
- **Hosting**: AWS EC2 with PM2 process manager

### Environment Variables
```env
# Ethereum Configuration
RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
WSS_PROVIDER=wss://sepolia.infura.io/ws/v3/YOUR_INFURA_PROJECT_ID

# Contract Configuration
CONTRACT_ADDRESS=YOUR_DEPLOYED_CONTRACT_ADDRESS
PRIVATE_KEY=YOUR_PRIVATE_KEY_FOR_CONTRACT_INTERACTION

# API Configuration
ML_API_URL=https://dex-9vfo.onrender.com/predict_fraud
```

## 🛠️ Troubleshooting

### Common Issues

#### Contract Deployment Fails
- Check RPC URL and network configuration
- Verify private key format (remove 0x prefix)
- Ensure sufficient ETH for gas fees
- Check contract compilation

#### AWS Deployment Issues
- Verify AWS credentials and permissions
- Check security group rules
- Ensure key pair exists in the specified region
- Monitor instance health

#### Mempool Listener Issues
- Verify WebSocket connection
- Check environment variables
- Monitor PM2 logs: `pm2 logs mempool-listener`
- Restart service if needed: `pm2 restart mempool-listener`

#### Integration Issues
- Verify contract address in all configurations
- Check ABI compatibility
- Test network connectivity
- Verify reporter permissions

### Useful Commands
```bash
# Check PM2 status
pm2 status

# View logs
pm2 logs mempool-listener

# Restart service
pm2 restart mempool-listener

# Check disk space
df -h

# Check memory usage
free -h

# Monitor AWS costs
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

## 🔒 Security Considerations

### Best Practices
- Never commit private keys to version control
- Use environment variables for sensitive data
- Restrict AWS security groups to necessary ports
- Monitor for suspicious activity
- Keep dependencies updated
- Use HTTPS for all connections

### Access Control
- Limit contract owner permissions
- Regularly audit reporter addresses
- Monitor contract events
- Set up alerts for unusual activity

## 💰 Cost Optimization

### AWS Costs
- **EC2 t3.medium**: ~$30/month
- **Data transfer**: Minimal for mempool monitoring
- **Storage**: 20GB EBS volume

### Optimization Tips
- Use spot instances for cost savings
- Set up billing alerts
- Monitor usage regularly
- Consider reserved instances for production

## 📊 Monitoring & Maintenance

### Health Checks
- Monitor mempool listener logs
- Check contract events on Etherscan
- Verify ML API connectivity
- Monitor AWS instance health

### Regular Maintenance
- Update dependencies monthly
- Review and rotate credentials
- Monitor AWS costs
- Backup important data
- Test system functionality

## 🆘 Emergency Procedures

### Service Restart
```bash
# Restart mempool listener
pm2 restart mempool-listener

# Check status
pm2 status
```

### Rollback Procedures
- Keep previous contract addresses
- Maintain backup configurations
- Document deployment steps
- Test rollback procedures

### Contact Information
- Document team contacts
- Set up incident response plan
- Maintain escalation procedures

## 🎉 Success Criteria

Your deployment is successful when:
- [ ] Smart contract deployed and verified on Sepolia
- [ ] Mempool listener running on AWS EC2
- [ ] Contract permissions properly configured
- [ ] Frontend updated and deployed on Vercel
- [ ] End-to-end testing completed
- [ ] Monitoring and alerts set up
- [ ] Documentation updated

## 📚 Additional Resources

- [Hardhat Documentation](https://hardhat.org/docs)
- [Ethers.js Documentation](https://docs.ethers.org/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [PM2 Documentation](https://pm2.keymetrics.io/docs/)
- [Sepolia Faucet](https://sepoliafaucet.com/)

## 🤝 Support

If you encounter issues during deployment:
1. Check the troubleshooting section
2. Review logs and error messages
3. Verify all prerequisites are met
4. Test each component individually
5. Consult the documentation

---

**Happy Deploying! 🚀**
