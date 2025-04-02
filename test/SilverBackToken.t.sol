// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SilverBackToken} from "../src/SilverBackToken.sol";

contract SilverBackTokenTest is Test {
    SilverBackToken token;
    address owner = address(0x1);
    address trader = address(0x2);
    address user = address(0x3);
    
    uint256 constant INITIAL_RESERVE = 1000; // 1000 troy ounces
    uint256 constant TRADER_LIMIT = 100 * 1e18; // 100 tokens
    
    function setUp() public {
        vm.startPrank(owner);
        token = new SilverBackToken();
        token.updateSilverReserve(INITIAL_RESERVE);
        vm.stopPrank();
    }
    
    function testTraderAuthorization() public {
        vm.startPrank(owner);
        
        // Authorize trader
        token.authorizeTrader(trader, TRADER_LIMIT);
        
        // Verify trader is authorized with correct limit
        (bool isAuthorized, uint256 mintLimit,,) = token.traders(trader);
        assertTrue(isAuthorized, "Trader should be authorized");
        assertEq(mintLimit, TRADER_LIMIT, "Trader mint limit should match");
        
        // Verify available minting capacity
        assertEq(token.getTraderMintingAvailable(trader), TRADER_LIMIT, "Initial available capacity should equal limit");
        
        vm.stopPrank();
    }
    
    function testTraderMinting() public {
        vm.startPrank(owner);
        token.authorizeTrader(trader, TRADER_LIMIT);
        vm.stopPrank();
        
        uint256 mintAmount = 50 * 1e18; // 50 tokens
        
        // Mint as trader
        vm.startPrank(trader);
        token.mint(user, mintAmount);
        vm.stopPrank();
        
        // Verify token balance
        assertEq(token.balanceOf(user), mintAmount, "User should have received tokens");
        
        // Verify remaining capacity
        assertEq(token.getTraderMintingAvailable(trader), TRADER_LIMIT - mintAmount, "Remaining capacity should be reduced");
    }
    
    function testTraderBurning() public {
        // Setup: authorize trader and mint tokens
        vm.startPrank(owner);
        token.authorizeTrader(trader, TRADER_LIMIT);
        token.mint(user, 100 * 1e18);
        vm.stopPrank();
        
        uint256 burnAmount = 50 * 1e18; // 50 tokens
        
        // Burn as trader
        vm.startPrank(trader);
        token.burn(user, burnAmount);
        vm.stopPrank();
        
        // Verify token balance
        assertEq(token.balanceOf(user), 50 * 1e18, "User should have fewer tokens");
        
        // Verify remaining capacity is increased due to burning
        assertEq(token.getTraderMintingAvailable(trader), TRADER_LIMIT, "Remaining capacity should be restored");
    }
    
    function testRevertWhen_ExceedingTraderLimit() public {
        // Setup: authorize trader
        vm.startPrank(owner);
        token.authorizeTrader(trader, TRADER_LIMIT);
        vm.stopPrank();
        
        // Try to mint more than limit
        vm.startPrank(trader);
        vm.expectRevert("Exceeds trader's minting limit");
        token.mint(user, TRADER_LIMIT + 1);
        vm.stopPrank();
    }
} 