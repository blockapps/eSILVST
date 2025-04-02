// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SilverBackToken.sol";
import "../src/SilverTrading.sol";
import "../src/SilverPriceFeed.sol";

/**
 * @title DeployScript
 * @notice Script for deploying the eSILVST contracts
 * 
 * This script performs the following actions:
 * 1. Deploys the SilverPriceFeed with initial price of $29.50/oz
 * 2. Deploys the SilverBackToken contract
 * 3. Sets the initial silver reserve to 1000 troy ounces
 * 4. Deploys the SilverTrading contract with a 500 token trading limit
 * 5. Authorizes the trading contract as a trader with the set limit
 */
contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy price feed first
        SilverPriceFeed priceFeed = new SilverPriceFeed(2950 * 1e6); // $29.50 per oz

        // Deploy SilverBackToken
        SilverBackToken token = new SilverBackToken();
        
        // Set initial silver reserve (1000 troy ounces)
        token.updateSilverReserve(1000);

        // Deploy SilverTrading with 500 token limit
        uint256 tradingLimit = 500 * 1e18; // 500 tokens
        SilverTrading trading = new SilverTrading(address(token), tradingLimit);
        
        // Authorize trading contract as a trader
        token.authorizeTrader(address(trading), tradingLimit);

        vm.stopBroadcast();
    }
}

/**
 * @title SepoliaDemo
 * @notice Script for demonstrating the eSILVST trading functionality
 * 
 * This script demonstrates a full trading workflow:
 * 1. Buying tokens with 0.1 ETH
 * 2. Selling half of the purchased tokens back for ETH
 * 
 * Requirements:
 * - Set TOKEN_ADDRESS in .env to the deployed token address
 * - Set TRADING_ADDRESS in .env to the deployed trading address
 * - Set USER_PRIVATE_KEY in .env to a private key with some Sepolia ETH
 */
contract SepoliaDemo is Script {
    function run() public {
        // Load the deployed contracts
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        address payable tradingAddress = payable(vm.envAddress("TRADING_ADDRESS"));
        SilverBackToken token = SilverBackToken(tokenAddress);
        SilverTrading trading = SilverTrading(tradingAddress);
        
        // Demo parameters
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);
        
        // Start the user transactions
        vm.startBroadcast(userPrivateKey);
        
        // 1. User buys tokens with ETH
        uint256 ethToSpend = 0.1 ether;
        uint256 expectedTokens = trading.getTokensForETH(ethToSpend);
        trading.buyTokensWithETH{value: ethToSpend}();
        
        // 2. User sells half the tokens for ETH
        uint256 userBalance = token.balanceOf(user);
        uint256 tokensToSell = userBalance / 2;
        uint256 expectedEth = trading.getETHForTokens(tokensToSell);
        
        // Approve the trading contract to spend the tokens
        token.approve(address(trading), tokensToSell);
        
        // Sell the tokens
        trading.sellTokensForETH(tokensToSell);
        
        vm.stopBroadcast();
    }
} 