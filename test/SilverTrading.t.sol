// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SilverBackToken} from "../src/SilverBackToken.sol";
import {SilverTrading} from "../src/SilverTrading.sol";

contract SilverTradingTest is Test {
    SilverBackToken token;
    SilverTrading trading;
    
    address owner = address(0x1);
    address user = address(0x2);
    
    uint256 constant INITIAL_RESERVE = 1000; // 1000 troy ounces
    uint256 constant INITIAL_TOKENS_FOR_TRADING = 500 * 1e18; // 500 tokens
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy token
        token = new SilverBackToken();
        token.updateSilverReserve(INITIAL_RESERVE);
        
        // Deploy trading contract
        trading = new SilverTrading(address(token));
        
        // Mint tokens to trading contract for liquidity
        token.mint(address(trading), INITIAL_TOKENS_FOR_TRADING);
        
        // Fund trading contract with ETH
        vm.deal(address(trading), 10 ether);
        
        vm.stopPrank();
    }
    
    function testBuyTokensWithETH() public {
        // Fund user with ETH
        uint256 ethToSpend = 1 ether;
        vm.deal(user, ethToSpend);
        
        // Calculate expected tokens
        uint256 expectedTokens = trading.getTokensForETH(ethToSpend);
        uint256 initialTradingBalance = token.balanceOf(address(trading));

        // Buy tokens
        vm.startPrank(user);
        trading.buyTokensWithETH{value: ethToSpend}();
        vm.stopPrank();
        
        // Verify results
        assertEq(token.balanceOf(user), expectedTokens, "User should receive correct token amount");
        assertEq(address(user).balance, 0, "User ETH balance should be 0");
        assertEq(address(trading).balance, 11 ether, "Trading contract should have more ETH");
        // Verify trading contract token balance decreased
        assertEq(token.balanceOf(address(trading)), initialTradingBalance - expectedTokens, "Trading contract token balance incorrect");
    }
    
    function testSellTokensForETH() public {
        // Setup: Need tokens to sell. Mint some to user directly for simplicity in test
        uint256 userInitialTokens = 100 * 1e18;
        vm.startPrank(owner);
        token.mint(user, userInitialTokens);
        vm.stopPrank();
        
        // Define amount to sell
        uint256 tokensToSell = userInitialTokens / 2;
        uint256 initialTradingTokenBalance = token.balanceOf(address(trading));
        uint256 initialUserEthBalance = address(user).balance;
        uint256 initialTradingEthBalance = address(trading).balance;

        // Approve and sell tokens
        vm.startPrank(user);
        token.approve(address(trading), tokensToSell);
        
        // Calculate expected ETH return
        uint256 expectedEthReturn = trading.getETHForTokens(tokensToSell);
        
        // Sell tokens
        trading.sellTokensForETH(tokensToSell);
        vm.stopPrank();
        
        // Verify results
        assertEq(token.balanceOf(user), userInitialTokens - tokensToSell, "User should have fewer tokens");
        assertEq(address(user).balance, initialUserEthBalance + expectedEthReturn, "User should have received ETH");
        assertEq(address(trading).balance, initialTradingEthBalance - expectedEthReturn, "Trading contract should have less ETH");
        // Verify trading contract token balance increased
        assertEq(token.balanceOf(address(trading)), initialTradingTokenBalance + tokensToSell, "Trading contract token balance incorrect");
    }
    
    function testPriceUpdateAffectsExchangeRate() public {
        // Record initial rates
        uint256 initialTokensForOneETH = trading.getTokensForETH(1 ether);
        
        // Update prices
        vm.startPrank(owner);
        uint256 newSilverPrice = 3500 * 1e6; // $35.00 per oz
        uint256 ethPrice = trading.ethPriceUSD(); // Keep ETH price the same
        trading.updatePrices(newSilverPrice, ethPrice);
        vm.stopPrank();
        
        // Calculate new rate
        uint256 newTokensForOneETH = trading.getTokensForETH(1 ether);
        
        // Verify that increasing silver price means fewer tokens per ETH
        assertLt(newTokensForOneETH, initialTokensForOneETH, "Increasing silver price should decrease tokens per ETH");
    }
    
    function testRevertWhen_InsufficientTokenReserves() public {
        // Calculate how many tokens 10 ETH would buy
        uint256 tokensFor10ETH = trading.getTokensForETH(10 ether);
        
        // Make sure this exceeds our initial token allocation to the trading contract
        assertGt(tokensFor10ETH, INITIAL_TOKENS_FOR_TRADING, "Need more than initial tokens for this test");
        
        // Fund user with ETH
        vm.deal(user, 11 ether);
        
        // Try to buy more tokens than available in the trading contract
        vm.startPrank(user);
        vm.expectRevert("Insufficient token reserves"); // Should now come from the trading contract check
        trading.buyTokensWithETH{value: 11 ether}();
        vm.stopPrank();
    }
    
    function testRevertWhen_SmallTokenAmount() public {
        // Setup: Mint some tokens directly to user
        uint256 userInitialTokens = 1 * 1e18;
        vm.startPrank(owner);
        token.mint(user, userInitialTokens);
        vm.stopPrank();
        
        vm.startPrank(user);
        // Try to sell a very small amount that would result in 0 ETH
        uint256 tinyAmount = 1; // 1 wei of token
        token.approve(address(trading), tinyAmount);
        
        vm.expectRevert("Token amount too small"); // Check in sellTokensForETH
        trading.sellTokensForETH(tinyAmount);
        vm.stopPrank();
    }
    
    function testRevertWhen_InsufficientETHInContract() public {
        // Setup: Mint some tokens directly to user
        uint256 userInitialTokens = 1 * 1e18;
        vm.startPrank(owner);
        token.mint(user, userInitialTokens);
        vm.stopPrank();
        
        // Calculate ETH needed BEFORE draining
        uint256 ethToSend = trading.getETHForTokens(userInitialTokens);
        require(ethToSend > 1, "Calculated ETH to send must be > 1 wei for this test");

        // Get the trading contract balance
        uint256 tradingBalance = address(trading).balance;
        require(tradingBalance > ethToSend, "Trading contract initial balance must be > ethToSend");

        // Simulate draining ETH directly using vm.deal, leaving 1 wei
        vm.deal(address(trading), 1);
        // Optionally, credit the owner with the drained amount (though not strictly necessary for the test)
        vm.deal(owner, owner.balance + (tradingBalance - 1));
        
        // Check the balance was set correctly
        assertEq(address(trading).balance, 1, "Trading contract should have 1 wei left after vm.deal");
        
        // Try to sell tokens when the contract has insufficient ETH (1 wei < ethToSend)
        vm.startPrank(user);
        token.approve(address(trading), userInitialTokens);
        
        // Use expectRevert with simple bytes(string)
        vm.expectRevert(bytes("Insufficient ETH in contract"));
        trading.sellTokensForETH(userInitialTokens);
        
        vm.stopPrank();
    }
} 