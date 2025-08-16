import { ethers } from "ethers";
import dotenv from "dotenv";

dotenv.config();

// Contract ABI for FraudLogger
const FRAUD_LOGGER_ABI = [
  "function logFraud(bytes32 txHash, address sender, uint256 score, uint8 fraudType, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) external",
  "function setReporter(address r, bool v) external",
  "function reporters(address) external view returns (bool)"
];

class ContractInteraction {
  constructor() {
    this.provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    this.wallet = new ethers.Wallet(process.env.PRIVATE_KEY, this.provider);
    this.contract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      FRAUD_LOGGER_ABI,
      this.wallet
    );
  }

  async logFraudToContract(transactionData, fraudResult) {
    try {
      // Convert fraud result to contract parameters
      const txHash = transactionData.txHash || ethers.keccak256(ethers.toUtf8Bytes(JSON.stringify(transactionData)));
      const sender = transactionData.from_address;
      const score = Math.floor(fraudResult.fraud_score * 100); // Convert to integer percentage
      const fraudType = fraudResult.fraud_type || 0; // Default to 0 for unknown
      
      // For ETH transfers, use zero address for tokens
      const tokenIn = "0x0000000000000000000000000000000000000000";
      const tokenOut = "0x0000000000000000000000000000000000000000";
      const amountIn = ethers.parseEther(transactionData.value.toString());
      const amountOut = ethers.parseEther(transactionData.value.toString());

      console.log(`Logging fraud to contract: ${txHash}`);
      
      const tx = await this.contract.logFraud(
        txHash,
        sender,
        score,
        fraudType,
        tokenIn,
        tokenOut,
        amountIn,
        amountOut
      );

      await tx.wait();
      console.log(`Fraud logged to contract successfully. TX: ${tx.hash}`);
      
      return tx.hash;
    } catch (error) {
      console.error("Error logging fraud to contract:", error);
      throw error;
    }
  }

  async checkReporterStatus() {
    try {
      const isReporter = await this.contract.reporters(this.wallet.address);
      console.log(`Reporter status for ${this.wallet.address}: ${isReporter}`);
      return isReporter;
    } catch (error) {
      console.error("Error checking reporter status:", error);
      return false;
    }
  }
}

export default ContractInteraction;
