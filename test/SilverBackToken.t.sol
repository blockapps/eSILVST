// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SilverBackToken} from "../src/SilverBackToken.sol";

contract SilverBackTokenTest is Test {
    SilverBackToken token;
    address owner = address(0x1);
    address user = address(0x2);
    address nonOwner = address(0x3);
    
    uint256 constant INITIAL_RESERVE = 1000; // 1000 troy ounces
    
    function setUp() public {
        vm.startPrank(owner);
        token = new SilverBackToken();
        token.updateSilverReserve(INITIAL_RESERVE);
        vm.stopPrank();
    }
    
    function testMintAsOwner() public {
        uint256 mintAmount = 100 * 1e18; // 100 tokens
        
        vm.startPrank(owner);
        token.mint(user, mintAmount);
        vm.stopPrank();
        
        // Verify token balance
        assertEq(token.balanceOf(user), mintAmount, "User should have received tokens");
        assertEq(token.totalSupply(), mintAmount, "Total supply should match minted amount");
    }
    
    function testBurnAsOwner() public {
        // Setup: mint tokens first
        uint256 mintAmount = 100 * 1e18; // 100 tokens
        uint256 burnAmount = 40 * 1e18; // 40 tokens
        
        vm.startPrank(owner);
        token.mint(user, mintAmount);
        token.burn(user, burnAmount);
        vm.stopPrank();
        
        // Verify token balance and supply
        assertEq(token.balanceOf(user), mintAmount - burnAmount, "User should have correct balance after burn");
        assertEq(token.totalSupply(), mintAmount - burnAmount, "Total supply should be reduced");
    }
    
    function testUpdateSilverReserve() public {
        uint256 newReserve = 1500; // 1500 troy ounces
        
        vm.startPrank(owner);
        token.updateSilverReserve(newReserve);
        vm.stopPrank();
        
        assertEq(token.totalSilverReserve(), newReserve, "Silver reserve should be updated");
    }
    
    function testRevertWhen_NonOwnerMints() public {
        vm.startPrank(nonOwner);
        vm.expectRevert(); // Should revert with Ownable error
        token.mint(user, 100 * 1e18);
        vm.stopPrank();
    }
    
    function testRevertWhen_NonOwnerBurns() public {
        // Setup: mint tokens as owner
        vm.startPrank(owner);
        token.mint(user, 100 * 1e18);
        vm.stopPrank();
        
        // Try to burn as non-owner
        vm.startPrank(nonOwner);
        vm.expectRevert(); // Should revert with Ownable error
        token.burn(user, 50 * 1e18);
        vm.stopPrank();
    }
    
    function testRevertWhen_MintingExceedsReserve() public {
        // Try to mint more than reserve allows
        vm.startPrank(owner);
        vm.expectRevert("Insufficient silver reserve");
        token.mint(user, (INITIAL_RESERVE + 1) * 1e18);
        vm.stopPrank();
    }
    
    function testPause() public {
        // Pause the contract
        vm.startPrank(owner);
        token.pause();
        
        // Try to mint while paused
        vm.expectRevert(); // Any revert is fine
        token.mint(user, 100 * 1e18);
        
        // Try to transfer while paused (first mint some tokens and unpause)
        token.unpause();
        token.mint(user, 100 * 1e18);
        token.pause();
        
        vm.stopPrank();
        
        // Try to transfer while paused
        vm.startPrank(user);
        vm.expectRevert(); // Any revert is fine
        token.transfer(nonOwner, 50 * 1e18);
        vm.stopPrank();
    }
    
    function testGetReserveRatio() public {
        // Initial state - no tokens minted
        assertEq(token.getReserveRatio(), 0, "Ratio should be 0 when no tokens are minted");
        
        // Mint some tokens
        uint256 mintAmount = 500 * 1e18; // 500 tokens
        vm.startPrank(owner);
        token.mint(user, mintAmount);
        vm.stopPrank();
        
        // Reserve ratio should be 2e18 (1000 oz reserve / 500 tokens = 2.0)
        assertEq(token.getReserveRatio(), 2e18, "Reserve ratio should be 2.0");
    }
} 