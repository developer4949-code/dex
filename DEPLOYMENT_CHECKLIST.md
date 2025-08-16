# Deployment Checklist

## Pre-Deployment Setup

### 1. Ethereum Development Environment
- [ ] Create Infura account and get project ID
- [ ] Get Sepolia testnet ETH (use faucet)
- [ ] Create Etherscan account and get API key
- [ ] Set up MetaMask with Sepolia network

### 2. AWS Setup
- [ ] Create AWS account
- [ ] Install AWS CLI
- [ ] Configure AWS credentials
- [ ] Create EC2 key pair
- [ ] Set up IAM user with EC2 permissions

### 3. Environment Variables
Create `.env` file in `Dex's` directory:
- [ ] `RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID`
- [ ] `WSS_PROVIDER=wss://sepolia.infura.io/ws/v3/YOUR_INFURA_PROJECT_ID`
- [ ] `PRIVATE_KEY=your_private_key_here`
- [ ] `ETHERSCAN_API_KEY=your_etherscan_api_key`

## Step 1: Deploy Smart Contract

### 1.1 Navigate to blockchain directory
```bash
cd "Dex's"
```

### 1.2 Install dependencies
```bash
npm install
```

### 1.3 Compile contracts
```bash
npm run compile
```

### 1.4 Deploy to Sepolia
```bash
npx hardhat run scripts/deploy-with-verification.js --network sepolia
```

### 1.5 Save contract information
- [ ] Copy deployed contract address
- [ ] Save deployment-info.json file
- [ ] Verify contract on Etherscan (optional)

## Step 2: Deploy Mempool Listener on AWS

### 2.1 Prepare AWS deployment
- [ ] Update `aws-deploy.sh` with your key pair name
- [ ] Ensure AWS credentials are configured
- [ ] Make script executable: `chmod +x aws-deploy.sh`

### 2.2 Run AWS deployment
```bash
./aws-deploy.sh
```

### 2.3 Configure mempool listener
- [ ] SSH into EC2 instance
- [ ] Update `.env` file with:
  - [ ] `WSS_PROVIDER`
  - [ ] `RPC_URL`
  - [ ] `CONTRACT_ADDRESS` (from Step 1)
  - [ ] `PRIVATE_KEY` (for contract interaction)

### 2.4 Start the service
```bash
pm2 start mempool-listener
pm2 save
pm2 startup
```

## Step 3: Configure Contract Permissions

### 3.1 Set up reporter permissions
- [ ] Get the mempool listener's wallet address
- [ ] Call `setReporter(address, true)` on the contract
- [ ] Verify reporter status

### 3.2 Test contract interaction
- [ ] Send a test transaction on Sepolia
- [ ] Check if fraud detection works
- [ ] Verify events are logged to contract

## Step 4: Update Frontend

### 4.1 Update Vercel deployment
- [ ] Update contract address in frontend
- [ ] Update ABI if needed
- [ ] Redeploy frontend on Vercel

### 4.2 Test integration
- [ ] Test frontend connection to contract
- [ ] Verify event display
- [ ] Test user interactions

## Step 5: Monitoring and Maintenance

### 5.1 Set up monitoring
- [ ] Configure CloudWatch alarms
- [ ] Set up log monitoring
- [ ] Create health check endpoints

### 5.2 Regular maintenance
- [ ] Monitor AWS costs
- [ ] Check service logs regularly
- [ ] Update dependencies as needed
- [ ] Backup important data

## Troubleshooting Common Issues

### Contract Deployment Issues
- [ ] Check RPC URL and network
- [ ] Verify private key format
- [ ] Ensure sufficient ETH for gas
- [ ] Check contract compilation

### AWS Deployment Issues
- [ ] Verify AWS credentials
- [ ] Check security group rules
- [ ] Ensure key pair exists
- [ ] Check instance health

### Mempool Listener Issues
- [ ] Verify WebSocket connection
- [ ] Check environment variables
- [ ] Monitor PM2 logs
- [ ] Restart service if needed

### Integration Issues
- [ ] Verify contract address
- [ ] Check ABI compatibility
- [ ] Test network connectivity
- [ ] Verify reporter permissions

## Security Checklist

- [ ] Never commit private keys
- [ ] Use environment variables
- [ ] Restrict AWS security groups
- [ ] Monitor for suspicious activity
- [ ] Keep dependencies updated
- [ ] Use HTTPS for all connections

## Cost Optimization

- [ ] Monitor AWS usage
- [ ] Consider spot instances
- [ ] Set up billing alerts
- [ ] Optimize instance size
- [ ] Use reserved instances for production

## Final Verification

- [ ] Smart contract deployed and verified
- [ ] Mempool listener running on AWS
- [ ] Contract permissions configured
- [ ] Frontend updated and deployed
- [ ] End-to-end testing completed
- [ ] Monitoring set up
- [ ] Documentation updated

## Emergency Procedures

- [ ] Service restart procedures
- [ ] Rollback procedures
- [ ] Contact information
- [ ] Backup procedures
- [ ] Incident response plan
