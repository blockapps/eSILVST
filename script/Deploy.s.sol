// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/SilverBackToken.sol";
import "../src/SilverTrading.sol";

/**
 * @title DeployScript
 * @notice Script for deploying the eSILVST contracts
 * 
 * This script performs the following actions:
 * 1. Deploys the SilverBackToken contract
 * 2. Sets the initial silver reserve to 1000 troy ounces
 * 3. Deploys the SilverTrading contract with a 500 token trading limit
 * 4. Mints initial tokens to the trading contract
 * 
 * To deploy and verify:
 * forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 */
contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy SilverBackToken
        SilverBackToken token = new SilverBackToken();
        
        // Set initial silver reserve (1000 troy ounces)
        token.updateSilverReserve(1000);

        // Deploy SilverTrading - Removed tradingLimit argument
        SilverTrading trading = new SilverTrading(address(token));
        
        // Mint initial tokens to the trading contract (e.g., 500 tokens)
        uint256 initialTokensForTrading = 500 * 1e18; 
        token.mint(address(trading), initialTokensForTrading);

        // Log deployed contract addresses
        console.log("Deployed SilverBackToken at:", address(token));
        console.log("Deployed SilverTrading at:", address(trading));
        console.log("Minted", initialTokensForTrading / 1e18, "tokens to trading contract");
        
        // Add verification check reminder
        if (block.chainid != 31337) { // Only for real networks
            console.log("----------------------------------------------------");
            console.log("After deployment, check verification status at:");
            console.log("Token: https://sepolia.etherscan.io/address/%s#code", address(token));
            console.log("Trading: https://sepolia.etherscan.io/address/%s#code", address(trading));
            console.log("----------------------------------------------------");
        }

        vm.stopBroadcast();
    }
} 