// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "forge-std/Script.sol";
import "../src/SilverTraderV2.sol";
import "../src/SilverBackToken.sol";
import "../src/MockSilverPriceFeed.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock price feed first
        MockSilverPriceFeed priceFeed = new MockSilverPriceFeed();
        console.log("MockSilverPriceFeed deployed to:", address(priceFeed));

        // Deploy SilverBackToken
        SilverBackToken token = new SilverBackToken();
        console.log("SilverBackToken deployed to:", address(token));

        // Deploy SilverTraderV2
        SilverTraderV2 trader = new SilverTraderV2(address(token), address(priceFeed));
        console.log("SilverTraderV2 deployed to:", address(trader));

        // Transfer ownership of token to trader
        token.transferOwnership(address(trader));
        console.log("Transferred SilverBackToken ownership to trader");

        vm.stopBroadcast();
    }
} 