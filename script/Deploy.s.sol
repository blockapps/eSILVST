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

        vm.stopBroadcast();
    }
} 