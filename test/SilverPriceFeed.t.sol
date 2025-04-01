// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test} from "forge-std/Test.sol";
import {SilverPriceFeed} from "../src/SilverPriceFeed.sol";

contract SilverPriceFeedTest is Test {
    SilverPriceFeed public priceFeed;
    address public constant PRICE_PROVIDER = address(0x123);
    
    function setUp() public {
        vm.startPrank(PRICE_PROVIDER);
        priceFeed = new SilverPriceFeed(25 * 1e18); // $25 per troy ounce
        vm.stopPrank();
    }
    
    function testInitialPrice() public {
        assertEq(priceFeed.price(), 25 * 1e18);
    }
    
    function testUpdatePrice() public {
        uint256 newPrice = 30 * 1e18; // $30 per troy ounce
        
        vm.startPrank(PRICE_PROVIDER);
        priceFeed.updatePrice(newPrice);
        vm.stopPrank();
        
        assertEq(priceFeed.price(), newPrice);
    }
    
    function test_RevertWhen_UpdatingPriceToZero() public {
        vm.startPrank(PRICE_PROVIDER);
        vm.expectRevert("New price must be positive");
        priceFeed.updatePrice(0);
        vm.stopPrank();
    }
    
    function test_RevertWhen_NonOwnerUpdatingPrice() public {
        address nonOwner = address(0x456);
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        priceFeed.updatePrice(30 * 1e18);
        vm.stopPrank();
    }
    
    function test_RevertWhen_NonOwnerUpdatingPriceProvider() public {
        address nonOwner = address(0x456);
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        priceFeed.updatePriceProvider(address(0x789));
        vm.stopPrank();
    }
    
    function test_RevertWhen_UpdatingPriceProviderToZeroAddress() public {
        vm.startPrank(PRICE_PROVIDER);
        vm.expectRevert("Invalid address");
        priceFeed.updatePriceProvider(address(0));
        vm.stopPrank();
    }
} 