// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
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

        // Log deployed contract addresses
        console.log("Deployed SilverBackToken at:", address(token));
        console.log("Deployed SilverTrading at:", address(trading));
        console.log("Deployed SilverPriceFeed at:", address(priceFeed));

        vm.stopBroadcast();
    }
} 