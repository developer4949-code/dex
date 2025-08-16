const { ethers } = require("hardhat");

async function main() {
  console.log("Starting FraudLogger deployment...");
  
  // Get the contract factory
  const FraudLogger = await ethers.getContractFactory("FraudLogger");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);
  
  // Check balance
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");
  
  // Deploy the contract
  console.log("Deploying FraudLogger...");
  const fraudLogger = await FraudLogger.deploy(deployer.address);
  
  // Wait for deployment
  await fraudLogger.waitForDeployment();
  
  // Get the deployed address
  const contractAddress = await fraudLogger.getAddress();
  console.log("FraudLogger deployed to:", contractAddress);
  
  // Verify the deployment
  console.log("Verifying deployment...");
  const deployedCode = await deployer.provider.getCode(contractAddress);
  if (deployedCode === "0x") {
    throw new Error("Contract deployment failed - no code at address");
  }
  console.log("✅ Contract deployed successfully!");
  
  // Set up initial reporter (the deployer)
  console.log("Setting up initial reporter...");
  const setReporterTx = await fraudLogger.setReporter(deployer.address, true);
  await setReporterTx.wait();
  console.log("✅ Deployer set as reporter");
  
  // Verify reporter status
  const isReporter = await fraudLogger.reporters(deployer.address);
  console.log("Deployer reporter status:", isReporter);
  
  // Log deployment information
  console.log("\n" + "=".repeat(50));
  console.log("DEPLOYMENT SUMMARY");
  console.log("=".repeat(50));
  console.log("Contract: FraudLogger");
  console.log("Address:", contractAddress);
  console.log("Network:", network.name);
  console.log("Deployer:", deployer.address);
  console.log("Owner:", await fraudLogger.owner());
  console.log("=".repeat(50));
  
  // Save deployment info to file
  const deploymentInfo = {
    contract: "FraudLogger",
    address: contractAddress,
    network: network.name,
    deployer: deployer.address,
    owner: await fraudLogger.owner(),
    deploymentTime: new Date().toISOString(),
    blockNumber: await fraudLogger.runner.provider.getBlockNumber()
  };
  
  const fs = require('fs');
  fs.writeFileSync(
    'deployment-info.json', 
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log("Deployment info saved to deployment-info.json");
  
  console.log("\nNext steps:");
  console.log("1. Update your .env file with CONTRACT_ADDRESS=" + contractAddress);
  console.log("2. Update your frontend with the new contract address");
  console.log("3. Deploy the mempool listener to AWS");
  console.log("4. Set the mempool listener address as a reporter in the contract");
}

main().catch((error) => {
  console.error("Deployment failed:", error);
  process.exitCode = 1;
});
