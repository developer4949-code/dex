import { ethers } from "ethers";
import fetch from "node-fetch";
import dotenv from "dotenv";
import ContractInteraction from "./contract-interaction.js";

dotenv.config();

// Initialize contract interaction
const contractInteraction = new ContractInteraction();

// Function to send transaction data to /predict_fraud
async function predictFraud(transactionData) {
  try {
    const response = await fetch("https://dex-9vfo.onrender.com/predict_fraud", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(transactionData)
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const result = await response.json();
    console.log("Fraud prediction result:", result);
    return result;
  } catch (err) {
    console.error("Error calling /predict_fraud:", err);
    return null;
  }
}

// Function to process fraud detection and log to contract
async function processFraudDetection(transactionData) {
  try {
    // Get fraud prediction from ML API
    const fraudResult = await predictFraud(transactionData);
    
    if (!fraudResult) {
      console.log("No fraud result received, skipping contract interaction");
      return;
    }

    // Check if fraud score is above threshold (e.g., 0.7)
    const fraudThreshold = 0.7;
    if (fraudResult.fraud_score > fraudThreshold) {
      console.log(`High fraud score detected: ${fraudResult.fraud_score}`);
      
      // Log to blockchain contract
      try {
        await contractInteraction.logFraudToContract(transactionData, fraudResult);
        console.log("Fraud logged to blockchain successfully");
      } catch (contractError) {
        console.error("Failed to log to contract:", contractError);
      }
    } else {
      console.log(`Low fraud score: ${fraudResult.fraud_score}, not logging to contract`);
    }
  } catch (error) {
    console.error("Error in fraud detection process:", error);
  }
}

// Initialize WebSocket provider
const provider = new ethers.WebSocketProvider(process.env.WSS_PROVIDER);

console.log("Starting mempool listener...");
console.log("Connected to:", process.env.WSS_PROVIDER);

// Check reporter status on startup
contractInteraction.checkReporterStatus().then(isReporter => {
  if (!isReporter) {
    console.warn("Warning: This address is not set as a reporter in the contract!");
  }
});

// Handle WebSocket connection events
provider.on("connect", () => {
  console.log("WebSocket connected successfully");
});

provider.on("error", (error) => {
  console.error("WebSocket error:", error);
});

provider.on("close", () => {
  console.log("WebSocket connection closed");
});

// Listen to pending transactions
provider.on("pending", async (txHash) => {
  setTimeout(async () => {
    try {
      const tx = await provider.getTransaction(txHash);
      if (!tx) return;
      
      // Only process transactions with value (ETH transfers)
      if (tx.value > 0n) {
        console.log(`\n--- New Pending Transaction ---`);
        console.log(`TX Hash: ${txHash}`);
        console.log(`From: ${tx.from} → To: ${tx.to}`);
        console.log(`Value: ${ethers.formatEther(tx.value)} ETH`);
        console.log(`Gas Price: ${ethers.formatUnits(tx.gasPrice || 0, 'gwei')} gwei`);
       
        const transactionData = {
          txHash: txHash,
          wallet_address: tx.from,
          timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19),
          token_pair: "ETH/ETH", 
          amount: Number(ethers.formatEther(tx.value)), 
          total_value_locked_usd: 0, 
          liquidity_change: 0, 
          price_usd: 0, 
          price_change: 0, 
          gasPrice: Number(tx.gasPrice || 0),
          gasUsed: Number(tx.gasLimit || 0),
          value: Number(ethers.formatEther(tx.value)),
          from_address: tx.from,
          to_address: tx.to
        };

        // Process fraud detection
        await processFraudDetection(transactionData);
      }
    } catch (err) {
      if (err.code !== 'UNPREDICTABLE_GAS_LIMIT') {
        console.log("Error fetching transaction:", err.code || err.message);
      }
    }
  }, 500); // Small delay to ensure transaction is available
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\nShutting down mempool listener...');
  provider.destroy();
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\nShutting down mempool listener...');
  provider.destroy();
  process.exit(0);
});

console.log("Listening to mempool transactions...");
