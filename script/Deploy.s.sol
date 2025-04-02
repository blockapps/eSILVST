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
 * 6. Automatically verifies all contracts on Etherscan
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
        
        // Auto-verify contracts (this runs after broadcasting)
        if (block.chainid != 31337) { // Skip verification for local development
            verifyContract(address(token), "SilverBackToken", "");
            verifyContract(address(trading), "SilverTrading", 
                abi.encode(address(token), tradingLimit));
            verifyContract(address(priceFeed), "SilverPriceFeed", 
                abi.encode(2950 * 1e6));
        }
    }
    
    function verifyContract(address contractAddress, string memory contractName, bytes memory constructorArgs) internal {
        // Get Etherscan API key from environment
        string memory etherscanApiKey = vm.envString("ETHERSCAN_API_KEY");
        
        // Create verification command
        string[] memory cmds = new string[](13);
        cmds[0] = "forge";
        cmds[1] = "verify-contract";
        cmds[2] = "--chain-id";
        cmds[3] = vm.toString(block.chainid);
        cmds[4] = "--watch"; // Monitor verification status
        cmds[5] = "--constructor-args";
        cmds[6] = vm.toHexString(constructorArgs);
        cmds[7] = vm.toString(contractAddress);
        cmds[8] = string(abi.encodePacked("src/", contractName, ".sol:", contractName));
        cmds[9] = "--etherscan-api-key";
        cmds[10] = etherscanApiKey;
        cmds[11] = "--retries";
        cmds[12] = "5"; // Number of retries
        
        // Log verification attempt
        console.log("Verifying", contractName, "at", vm.toString(contractAddress));
        
        // Execute verification (will show output in terminal)
        vm.ffi(cmds);
        
        console.log(contractName, "verification complete");
    }
} 