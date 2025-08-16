// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/access/Ownable.sol";

contract FraudLogger is Ownable {
    event FraudDetected(
        bytes32 indexed txHash,
        address indexed sender,
        uint256 score,
        uint8 fraudType,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 ts
    );

    mapping(address => bool) public reporters;

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setReporter(address r, bool v) external onlyOwner {
        reporters[r] = v;
    }

    function logFraud(
        bytes32 txHash,
        address sender,
        uint256 score,
        uint8 fraudType,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) external {
        require(reporters[msg.sender], "not reporter");
        emit FraudDetected(
            txHash,
            sender,
            score,
            fraudType,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut,
            block.timestamp
        );
    }
}
