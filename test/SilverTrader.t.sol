// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test} from "forge-std/Test.sol";
import {SilverTrader} from "../src/SilverTrader.sol";
import {SilverBackToken} from "../src/SilverBackToken.sol";
import {SilverPriceFeed} from "../src/SilverPriceFeed.sol";

contract SilverTraderTest is Test {
    SilverTrader public trader;
    SilverBackToken public sbt;
    SilverPriceFeed public priceFeed;
    
    address public constant PRICE_PROVIDER = address(0x123);
    address public constant USER = address(0xabc);
    
    uint256 public constant INITIAL_PRICE = 25e18; // $25 per troy ounce
    uint256 public constant INITIAL_SILVER = 1000e18; // 1000 troy ounces
    uint256 public constant TRADE_AMOUNT = 100e18; // 100 troy ounces
    
    function setUp() public {
        // Deploy contracts
        vm.startPrank(PRICE_PROVIDER);
        priceFeed = new SilverPriceFeed(INITIAL_PRICE);
        vm.stopPrank();
        
        sbt = new SilverBackToken();
        trader = new SilverTrader(
            address(sbt),
            address(priceFeed)
        );
        
        // Setup initial state
        vm.deal(USER, 100 ether);
    }
    
    function testBuySilver() public {
        uint256 buyAmount = 10 ether; // 10 ETH
        uint256 expectedSilver = (buyAmount * 1e18) / INITIAL_PRICE;
        
        vm.startPrank(USER);
        trader.buySilver{value: buyAmount}();
        vm.stopPrank();
        
        assertEq(sbt.balanceOf(USER), expectedSilver);
    }
    
    function testSellSilver() public {
        // First buy some silver
        uint256 buyAmount = 10 ether;
        uint256 silverAmount = (buyAmount * 1e18) / INITIAL_PRICE;
        
        vm.startPrank(USER);
        trader.buySilver{value: buyAmount}();
        
        uint256 balanceBefore = USER.balance;
        
        // Then sell half of it
        uint256 sellAmount = silverAmount / 2;
        sbt.approve(address(trader), sellAmount);
        trader.sellSilver(sellAmount);
        vm.stopPrank();
        
        uint256 expectedEth = (sellAmount * INITIAL_PRICE) / 1e18;
        assertEq(USER.balance - balanceBefore, expectedEth);
        assertEq(sbt.balanceOf(USER), silverAmount - sellAmount);
    }
    
    function test_RevertWhen_BuyingWithZeroEth() public {
        vm.startPrank(USER);
        vm.expectRevert("Must send ETH to buy silver");
        trader.buySilver{value: 0}();
        vm.stopPrank();
    }
    
    function test_RevertWhen_SellingZeroAmount() public {
        vm.startPrank(USER);
        vm.expectRevert("Amount must be greater than 0");
        trader.sellSilver(0);
        vm.stopPrank();
    }
    
    function test_RevertWhen_ContractPaused() public {
        vm.startPrank(address(trader.owner()));
        trader.pause();
        vm.stopPrank();
        
        vm.startPrank(USER);
        vm.expectRevert("Pausable: paused");
        trader.buySilver{value: 1 ether}();
        vm.stopPrank();
    }
    
    function test_RevertWhen_NonOwnerPausing() public {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        trader.pause();
        vm.stopPrank();
    }
    
    function test_RevertWhen_NonOwnerUnpausing() public {
        vm.startPrank(address(trader.owner()));
        trader.pause();
        vm.stopPrank();
        
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        trader.unpause();
        vm.stopPrank();
    }
} 