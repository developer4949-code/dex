const { ethers } = require("hardhat");

async function main() {
  const FraudLogger = await ethers.getContractFactory("FraudLogger");
  const fraudLogger = await FraudLogger.deploy("0xFd9EbB184C893F3cadc4C134FDCdf4c742E3c838");
  await fraudLogger.waitForDeployment();
  console.log("FraudLogger deployment result:", fraudLogger);
  // ethers v6: address is available as fraudLogger.target
  console.log("FraudLogger deployed to:", fraudLogger.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
