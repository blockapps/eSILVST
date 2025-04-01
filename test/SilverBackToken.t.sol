// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test} from "forge-std/Test.sol";
import {SilverBackToken} from "../src/SilverBackToken.sol";

contract SilverBackTokenTest is Test {
    SilverBackToken token;
    address owner = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);
    
    uint256 constant INITIAL_SILVER = 1000;
    uint256 constant INITIAL_TOKENS = INITIAL_SILVER * 1e18;
    
    function setUp() public {
        vm.startPrank(owner);
        token = new SilverBackToken();
        token.updateSilverReserve(INITIAL_SILVER);
        token.mint(owner, INITIAL_TOKENS);
        vm.stopPrank();
    }
    
    function testInitialState() public {
        assertEq(token.totalSilverReserve(), INITIAL_SILVER);
        assertEq(token.totalSupply(), INITIAL_TOKENS);
        assertEq(token.balanceOf(owner), INITIAL_TOKENS);
    }
    
    function testMint() public {
        uint256 amount = 100 * 1e18;
        
        vm.startPrank(owner);
        token.updateSilverReserve(INITIAL_SILVER + 100); // Update reserve before minting
        token.mint(user1, amount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.totalSupply(), INITIAL_TOKENS + amount);
    }
    
    function testBurn() public {
        uint256 amount = 100 * 1e18;
        
        vm.prank(owner);
        token.burn(owner, amount);
        
        assertEq(token.balanceOf(owner), INITIAL_TOKENS - amount);
        assertEq(token.totalSupply(), INITIAL_TOKENS - amount);
    }
    
    function testTransfer() public {
        uint256 amount = 100 * 1e18;
        
        vm.prank(owner);
        token.transfer(user1, amount);
        
        assertEq(token.balanceOf(owner), INITIAL_TOKENS - amount);
        assertEq(token.balanceOf(user1), amount);
    }
    
    function test_RevertWhen_MintingExceedsReserve() public {
        uint256 amount = (INITIAL_SILVER + 1) * 1e18;
        
        vm.prank(owner);
        vm.expectRevert("Insufficient silver reserve");
        token.mint(user1, amount);
    }
    
    function test_RevertWhen_BurningInsufficientBalance() public {
        uint256 amount = INITIAL_TOKENS + 1;
        
        vm.prank(owner);
        vm.expectRevert("Insufficient balance");
        token.burn(owner, amount);
    }
    
    function test_RevertWhen_TransferringWhilePaused() public {
        vm.startPrank(owner);
        token.pause();
        vm.expectRevert("Pausable: paused");
        token.transfer(user1, 100 * 1e18);
        vm.stopPrank();
    }
} 