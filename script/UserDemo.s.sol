// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SilverBackToken.sol";
import "../src/SilverTrading.sol";

/**
 * @title BuyTokensDemo
 * @notice Script for demonstrating only the token purchase flow
 * 
 * User flow:
 * 1. User starts with ETH and no tokens
 * 2. User calls buyTokensWithETH() sending a small amount of ETH (0.0005 ETH)
 * 3. User receives tokens based on current ETH and silver prices
 * 
 * Expected state changes:
 * - User's ETH balance decreases by the amount sent
 * - User's token balance increases from 0 to the calculated amount
 * - Trading contract's ETH balance increases
 * - Token supply increases
 * 
 * Requirements:
 * - Set TOKEN_ADDRESS in .env to the deployed token address
 * - Set TRADING_ADDRESS in .env to the deployed trading address
 * - Set USER_PRIVATE_KEY in .env to a private key with some Sepolia ETH
 */
contract BuyTokensDemo is Script {
    function run() public {
        // Load the deployed contracts
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        address payable tradingAddress = payable(vm.envAddress("TRADING_ADDRESS"));
        SilverBackToken token = SilverBackToken(tokenAddress);
        SilverTrading trading = SilverTrading(tradingAddress);
        
        // Demo parameters
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);
        
        // Log initial state
        console.log("--- INITIAL STATE ---");
        console.log("User address:", user);
        console.log("Token address:", tokenAddress);
        console.log("Trading address:", tradingAddress);
        
        uint256 initialEthBalance = user.balance;
        uint256 initialTokenBalance = token.balanceOf(user);
        console.log("Initial ETH balance (wei):", initialEthBalance);
        console.log("Initial token balance:", initialTokenBalance);
        
        // Start the user transactions
        vm.startBroadcast(userPrivateKey);
        
        // Buy tokens with ETH - use a very small amount to avoid running out of funds
        uint256 ethToSpend = 0.0003 ether; // Reduced from 0.0005 to ensure we have enough gas
        
        // Calculate expected tokens (just for logging)
        uint256 expectedTokens = trading.getTokensForETH(ethToSpend);
        console.log("Sending ETH amount (wei):", ethToSpend);
        console.log("Expected tokens return:", expectedTokens);
        
        // Execute the buy with explicit gas limit
        // Note: Setting a higher gas limit than default to ensure transaction completes
        try trading.buyTokensWithETH{value: ethToSpend, gas: 500000}() {
            console.log("Transaction succeeded!");
            
            // Check final state
            uint256 finalTokenBalance = token.balanceOf(user);
            console.log("--- FINAL STATE ---");
            console.log("Final token balance:", finalTokenBalance);
            console.log("Tokens received:", finalTokenBalance - initialTokenBalance);
            
        } catch Error(string memory reason) {
            console.log("Transaction failed with reason:", reason);
        } catch (bytes memory) {
            console.log("Transaction failed with unknown error");
        }
        
        vm.stopBroadcast();
    }
} 