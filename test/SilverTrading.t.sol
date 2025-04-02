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
    uint256 constant TRADING_LIMIT = 500 * 1e18; // 500 tokens
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy token
        token = new SilverBackToken();
        token.updateSilverReserve(INITIAL_RESERVE);
        
        // Deploy trading contract
        trading = new SilverTrading(address(token), TRADING_LIMIT);
        
        // Authorize trading contract
        token.authorizeTrader(address(trading), TRADING_LIMIT);
        
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
        
        // Buy tokens
        vm.startPrank(user);
        trading.buyTokensWithETH{value: ethToSpend}();
        vm.stopPrank();
        
        // Verify results
        assertEq(token.balanceOf(user), expectedTokens, "User should receive correct token amount");
        assertEq(address(user).balance, 0, "User ETH balance should be 0");
        assertEq(address(trading).balance, 11 ether, "Trading contract should have more ETH");
    }
    
    function testSellTokensForETH() public {
        // Setup: Buy tokens first
        uint256 ethToSpend = 1 ether;
        vm.deal(user, ethToSpend);
        
        vm.startPrank(user);
        trading.buyTokensWithETH{value: ethToSpend}();
        
        // Get token balance
        uint256 tokenBalance = token.balanceOf(user);
        uint256 tokensToSell = tokenBalance / 2;
        
        // Approve and sell tokens
        token.approve(address(trading), tokensToSell);
        
        // Calculate expected ETH return
        uint256 expectedEthReturn = trading.getETHForTokens(tokensToSell);
        
        // Sell tokens
        trading.sellTokensForETH(tokensToSell);
        vm.stopPrank();
        
        // Verify results
        assertEq(token.balanceOf(user), tokenBalance - tokensToSell, "User should have fewer tokens");
        assertEq(address(user).balance, expectedEthReturn, "User should have received ETH");
        assertEq(address(trading).balance, 11 ether - expectedEthReturn, "Trading contract should have less ETH");
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
} 