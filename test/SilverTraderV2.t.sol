// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {SilverTraderV2} from "../src/SilverTraderV2.sol";
import {SilverBackToken} from "../src/SilverBackToken.sol";
import {SilverPriceFeed} from "../src/SilverPriceFeed.sol";
import {MockSilverPriceFeed} from "../src/test/MockSilverPriceFeed.sol";

contract SilverTraderV2Test is Test {
    event LogState(
        string label,
        uint256 userEthBalance,
        uint256 userSilverBalance,
        uint256 traderEthBalance,
        uint256 traderSilverBalance,
        uint256 totalSupply,
        uint256 silverReserve,
        uint256 silverPrice
    );

    address constant USER = address(0xABC);
    address constant OWNER = address(0x123);
    uint256 constant INITIAL_PRICE = 25 ether;
    uint256 constant INITIAL_SILVER = 1000 ether;

    SilverBackToken sbt;
    MockSilverPriceFeed priceFeed;
    SilverTraderV2 trader;
    
    uint256 public constant PRICE_PRECISION = 1e18;
    
    function setUp() public {
        vm.startPrank(OWNER);
        
        // Deploy contracts
        sbt = new SilverBackToken();
        priceFeed = new MockSilverPriceFeed(INITIAL_PRICE);
        trader = new SilverTraderV2(address(sbt), address(priceFeed));
        
        // Set up ownership
        sbt.transferOwnership(address(trader));
        
        vm.stopPrank();
        
        // Set up initial silver reserve
        vm.startPrank(address(trader));
        sbt.updateSilverReserve(INITIAL_SILVER / 1e18);
        vm.stopPrank();
        
        vm.deal(USER, 100 ether);
    }
    
    function testInitialState() public {
        assertEq(address(trader.sbt()), address(sbt));
        assertEq(address(trader.priceFeed()), address(priceFeed));
        assertEq(sbt.balanceOf(address(trader)), INITIAL_SILVER);
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
    
    function testDepositSilver() public {
        uint256 amount = 100e18;
        sbt.updateSilverReserve((INITIAL_SILVER + amount) / 1e18); // Update reserve first
        sbt.mint(address(this), amount);
        sbt.approve(address(trader), amount);
        
        trader.depositSilver(amount);
        assertEq(sbt.balanceOf(address(trader)), INITIAL_SILVER + amount);
    }
    
    function testWithdrawSilver() public {
        uint256 amount = 100e18;
        
        vm.startPrank(address(trader.owner()));
        trader.withdrawSilver(amount);
        vm.stopPrank();
        
        assertEq(sbt.balanceOf(address(trader)), INITIAL_SILVER - amount);
    }
    
    function testWithdrawETH() public {
        // First buy some silver to get ETH in the contract
        uint256 ethAmount = 25 ether;
        
        vm.startPrank(USER);
        trader.buySilver{value: ethAmount}();
        vm.stopPrank();
        
        // Create a payable address for the owner
        address payable owner = payable(address(0x1234));
        vm.deal(owner, 0); // Ensure owner has no ETH initially
        
        // Transfer ownership from the current owner to the new owner
        address currentOwner = trader.owner();
        vm.startPrank(currentOwner);
        trader.transferOwnership(owner);
        vm.stopPrank();
        
        uint256 balanceBefore = owner.balance;
        
        vm.startPrank(owner);
        trader.withdrawETH(ethAmount);
        vm.stopPrank();
        
        assertEq(address(trader).balance, 0);
        assertEq(owner.balance, balanceBefore + ethAmount);
    }
    
    function test_RevertWhen_NonOwnerWithdrawing() public {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        trader.withdrawSilver(100e18);
        vm.stopPrank();
    }
    
    function test_eSILVST_Redemption_Flow() public {
        emit LogState(
            "Initial State",
            USER.balance,
            sbt.balanceOf(USER),
            address(trader).balance,
            sbt.balanceOf(address(trader)),
            sbt.totalSupply(),
            sbt.totalSilverReserve(),
            priceFeed.price()
        );
        
        // Buy silver tokens
        vm.startPrank(USER);
        uint256 buyAmount = 10 ether;
        uint256 expectedSilver = (buyAmount * 1e18) / INITIAL_PRICE;
        
        trader.buySilver{value: buyAmount}();
        
        emit LogState(
            "After Buy",
            USER.balance,
            sbt.balanceOf(USER),
            address(trader).balance,
            sbt.balanceOf(address(trader)),
            sbt.totalSupply(),
            sbt.totalSilverReserve(),
            priceFeed.price()
        );
        
        // Sell silver tokens
        sbt.approve(address(trader), expectedSilver);
        uint256 initialBalance = USER.balance;
        
        trader.sellSilver(expectedSilver);
        
        emit LogState(
            "Final State",
            USER.balance,
            sbt.balanceOf(USER),
            address(trader).balance,
            sbt.balanceOf(address(trader)),
            sbt.totalSupply(),
            sbt.totalSilverReserve(),
            priceFeed.price()
        );
        
        // Verify final state
        assertEq(sbt.balanceOf(USER), 0, "User should have no silver tokens after selling");
        assertEq(USER.balance, initialBalance + buyAmount, "User should receive correct amount of ETH back");
        
        vm.stopPrank();
    }
} 