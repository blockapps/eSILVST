// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SilverBackToken.sol";
import "../src/SilverTrading.sol";
import "../src/SilverPriceFeed.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=== Deploying eSILVST Contracts ===");

        // Deploy price feed first
        SilverPriceFeed priceFeed = new SilverPriceFeed(2950 * 1e6); // $29.50 per oz
        console.log("SilverPriceFeed deployed to:", address(priceFeed));

        // Deploy SilverBackToken
        SilverBackToken token = new SilverBackToken();
        console.log("SilverBackToken deployed to:", address(token));
        
        // Set initial silver reserve (1000 troy ounces)
        token.updateSilverReserve(1000);
        console.log("Set initial silver reserve to 1000 troy ounces");

        // Deploy SilverTrading with 500 token limit
        uint256 tradingLimit = 500 * 1e18; // 500 tokens
        SilverTrading trading = new SilverTrading(address(token), tradingLimit);
        console.log("SilverTrading deployed to:", address(trading));
        
        // Authorize trading contract as a trader
        token.authorizeTrader(address(trading), tradingLimit);
        console.log("Authorized SilverTrading as a trader with limit:", tradingLimit);

        // Fund the trading contract with some ETH for demonstration
        // Note: In a real scenario, the contract would receive ETH from users
        // payable(address(trading)).transfer(1 ether);
        console.log("=== Deployment Complete ===");

        vm.stopBroadcast();
    }
}

contract SepoliaDemo is Script {
    function run() public {
        // Load the deployed contracts
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        address tradingAddress = vm.envAddress("TRADING_ADDRESS");
        SilverBackToken token = SilverBackToken(tokenAddress);
        SilverTrading trading = SilverTrading(tradingAddress);
        
        // Demo parameters
        uint256 userPrivateKey = vm.envUint("USER_PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);
        
        console.log("=== Running eSILVST Demo ===");
        console.log("User address:", user);
        console.log("Token address:", tokenAddress);
        console.log("Trading address:", tradingAddress);
        
        // Show initial state
        console.log("\n=== Initial State ===");
        console.log("User ETH balance:", address(user).balance / 1e18, "ETH");
        console.log("User token balance:", token.balanceOf(user) / 1e18, "eSILVST");
        console.log("Trading contract ETH balance:", address(trading).balance / 1e18, "ETH");
        console.log("Total token supply:", token.totalSupply() / 1e18, "eSILVST");
        console.log("Silver reserve:", token.totalSilverReserve(), "troy ounces");
        
        // User buys tokens with ETH
        vm.startBroadcast(userPrivateKey);
        
        console.log("\n=== Buying Tokens with ETH ===");
        uint256 ethToSpend = 0.1 ether;
        uint256 expectedTokens = trading.getTokensForETH(ethToSpend);
        console.log("Spending", ethToSpend / 1e18, "ETH to buy approximately", expectedTokens / 1e18, "eSILVST tokens");
        
        trading.buyTokensWithETH{value: ethToSpend}();
        
        console.log("\n=== After Buying ===");
        console.log("User ETH balance:", address(user).balance / 1e18, "ETH");
        console.log("User token balance:", token.balanceOf(user) / 1e18, "eSILVST");
        console.log("Trading contract ETH balance:", address(trading).balance / 1e18, "ETH");
        
        // User sells half the tokens for ETH
        console.log("\n=== Selling Tokens for ETH ===");
        uint256 userBalance = token.balanceOf(user);
        uint256 tokensToSell = userBalance / 2;
        uint256 expectedEth = trading.getETHForTokens(tokensToSell);
        
        console.log("Selling", tokensToSell / 1e18, "eSILVST tokens for approximately", expectedEth / 1e18, "ETH");
        
        // Approve the trading contract to spend the tokens
        token.approve(address(trading), tokensToSell);
        
        // Sell the tokens
        trading.sellTokensForETH(tokensToSell);
        
        console.log("\n=== After Selling ===");
        console.log("User ETH balance:", address(user).balance / 1e18, "ETH");
        console.log("User token balance:", token.balanceOf(user) / 1e18, "eSILVST");
        console.log("Trading contract ETH balance:", address(trading).balance / 1e18, "ETH");
        console.log("Total token supply:", token.totalSupply() / 1e18, "eSILVST");
        
        vm.stopBroadcast();
        
        console.log("\n=== Demo Complete ===");
    }
} 