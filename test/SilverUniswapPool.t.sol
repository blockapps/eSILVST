// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Test, console} from "forge-std/Test.sol";
import {SilverUniswapPool} from "../src/SilverUniswapPool.sol";
import {SilverBackToken} from "../src/SilverBackToken.sol";
import {SilverTraderV2} from "../src/SilverTraderV2.sol";
import {SilverPriceFeed} from "../src/SilverPriceFeed.sol";
import {MockUniswapV3Pool} from "./mocks/MockUniswapV3Pool.sol";
import {MockNonfungiblePositionManager} from "./mocks/MockNonfungiblePositionManager.sol";
import {MockSwapRouter} from "./mocks/MockSwapRouter.sol";

contract SilverUniswapPoolTest is Test {
    SilverUniswapPool public pool;
    SilverBackToken public sbt;
    SilverTraderV2 public trader;
    SilverPriceFeed public priceFeed;
    MockUniswapV3Pool public mockPool;
    MockNonfungiblePositionManager public mockPositionManager;
    MockSwapRouter public mockSwapRouter;
    
    address public constant PRICE_PROVIDER = address(0x123);
    address public constant USER = address(0xabc);
    address public constant SWAP_ROUTER = address(0x456);
    address public constant POSITION_MANAGER = address(0x789);
    address public constant UNISWAP_POOL = address(0xdef);
    
    uint256 public constant INITIAL_PRICE = 25e18; // $25 per troy ounce
    uint256 public constant INITIAL_SILVER = 1000e18; // 1000 troy ounces
    uint256 public constant POSITION_AMOUNT = 100e18; // 100 troy ounces
    
    function setUp() public {
        // Deploy mock contracts
        mockPool = new MockUniswapV3Pool();
        mockPositionManager = new MockNonfungiblePositionManager();
        mockSwapRouter = new MockSwapRouter();
        
        // Deploy real contracts
        vm.startPrank(PRICE_PROVIDER);
        priceFeed = new SilverPriceFeed(INITIAL_PRICE);
        vm.stopPrank();
        
        sbt = new SilverBackToken();
        trader = new SilverTraderV2(
            address(sbt),
            address(priceFeed)
        );
        
        pool = new SilverUniswapPool(
            address(sbt),
            address(priceFeed),
            address(mockPositionManager),
            address(mockSwapRouter)
        );
        
        // Setup initial state
        sbt.mint(USER, POSITION_AMOUNT);
        vm.deal(USER, 100 ether);
    }
    
    function testInitialState() public {
        assertEq(address(pool.sbt()), address(sbt));
        assertEq(address(pool.swapRouter()), address(mockSwapRouter));
        assertEq(address(pool.positionManager()), address(mockPositionManager));
        assertEq(address(pool.priceFeed()), address(priceFeed));
    }
    
    function testCreatePosition() public {
        int24 tickLower = -10;
        int24 tickUpper = 10;
        uint256 amount0Desired = 50e18; // 50 troy ounces
        uint256 amount1Desired = 1 ether;
        
        vm.startPrank(USER);
        sbt.approve(address(pool), amount0Desired);
        uint256 tokenId = pool.mintPosition(
            tickLower,
            tickUpper,
            amount0Desired,
            amount1Desired,
            0, // amount0Min
            0, // amount1Min
            block.timestamp // deadline
        );
        vm.stopPrank();
        
        assertEq(tokenId, 1); // Mock returns 1
        assertEq(pool.getUserPositions(USER).length, 1);
        assertEq(pool.getUserPositions(USER)[0], tokenId);
    }
    
    function test_RevertWhen_CreatingPositionWithZeroAmount() public {
        vm.startPrank(USER);
        sbt.approve(address(pool), 100e18);
        vm.expectRevert("Amounts must be positive");
        pool.mintPosition(
            -10,
            10,
            0,
            1 ether,
            0,
            0,
            block.timestamp
        );
        vm.stopPrank();
    }
    
    function testClosePosition() public {
        // First create a position
        vm.startPrank(USER);
        sbt.approve(address(pool), 50e18);
        uint256 tokenId = pool.mintPosition(
            -10,
            10,
            50e18,
            1 ether,
            0,
            0,
            block.timestamp
        );
        
        // Then close it
        pool.burnPosition(tokenId);
        vm.stopPrank();
        
        assertEq(pool.getUserPositions(USER).length, 0);
    }
    
    function test_RevertWhen_ClosingNonOwnedPosition() public {
        // Create position as USER
        vm.startPrank(USER);
        sbt.approve(address(pool), 50e18);
        uint256 tokenId = pool.mintPosition(
            -10,
            10,
            50e18,
            1 ether,
            0,
            0,
            block.timestamp
        );
        vm.stopPrank();
        
        // Try to close as different user
        address otherUser = address(0x999);
        vm.startPrank(otherUser);
        vm.expectRevert("Not position owner");
        pool.burnPosition(tokenId);
        vm.stopPrank();
    }
    
    function testCollectFees() public {
        // First create a position
        vm.startPrank(USER);
        sbt.approve(address(pool), 50e18);
        uint256 tokenId = pool.mintPosition(
            -10,
            10,
            50e18,
            1 ether,
            0,
            0,
            block.timestamp
        );
        
        // Then collect fees
        pool.collect(tokenId, type(uint128).max, type(uint128).max);
        vm.stopPrank();
    }
    
    function test_RevertWhen_CollectingFeesFromNonOwnedPosition() public {
        // Create position as USER
        vm.startPrank(USER);
        sbt.approve(address(pool), 50e18);
        uint256 tokenId = pool.mintPosition(
            -10,
            10,
            50e18,
            1 ether,
            0,
            0,
            block.timestamp
        );
        vm.stopPrank();
        
        // Try to collect fees as different user
        address otherUser = address(0x999);
        vm.startPrank(otherUser);
        vm.expectRevert("Not position owner");
        pool.collect(tokenId, type(uint128).max, type(uint128).max);
        vm.stopPrank();
    }
    
    function test_RevertWhen_ContractPaused() public {
        vm.startPrank(address(pool.owner()));
        pool.pause();
        vm.stopPrank();
        
        vm.startPrank(USER);
        sbt.approve(address(pool), 50e18);
        vm.expectRevert("Pausable: paused");
        pool.mintPosition(
            -10,
            10,
            50e18,
            1 ether,
            0,
            0,
            block.timestamp
        );
        vm.stopPrank();
    }
    
    function test_RevertWhen_NonOwnerPausing() public {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        pool.pause();
        vm.stopPrank();
    }
    
    function test_RevertWhen_NonOwnerUnpausing() public {
        vm.startPrank(address(pool.owner()));
        pool.pause();
        vm.stopPrank();
        
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        pool.unpause();
        vm.stopPrank();
    }

    function test_eSILVST_Redemption_Flow() public {
        // Initial setup
        uint256 initialBalance = 100e18; // 100 eSILVST
        uint256 redemptionAmount = 50e18; // 50 eSILVST
        uint256 currentPrice = priceFeed.price(); // Get current silver price
        
        console.log("\n=== eSILVST Redemption Flow ===");
        console.log("Initial Setup:");
        console.log("User Address:", USER);
        console.log("Initial eSILVST Balance:", initialBalance);
        console.log("Current Silver Price:", currentPrice);
        console.log("Redemption Amount:", redemptionAmount);
        
        // Mint initial tokens to user
        vm.startPrank(address(trader));
        sbt.mint(USER, initialBalance);
        vm.stopPrank();
        
        console.log("\nAfter Initial Mint:");
        console.log("User eSILVST Balance:", sbt.balanceOf(USER));
        
        // User initiates redemption
        vm.startPrank(USER);
        uint256 userEthBalanceBefore = USER.balance;
        console.log("\nBefore Redemption:");
        console.log("User ETH Balance:", userEthBalanceBefore);
        console.log("User eSILVST Balance:", sbt.balanceOf(USER));
        
        // Approve and sell eSILVST
        sbt.approve(address(trader), redemptionAmount);
        trader.sellSilver(redemptionAmount);
        vm.stopPrank();
        
        // Log final state
        console.log("\nAfter Redemption:");
        console.log("User ETH Balance:", USER.balance);
        console.log("User eSILVST Balance:", sbt.balanceOf(USER));
        console.log("ETH Received:", USER.balance - userEthBalanceBefore);
        console.log("eSILVST Redeemed:", redemptionAmount);
        
        // Verify balances
        assertEq(sbt.balanceOf(USER), initialBalance - redemptionAmount, "Incorrect eSILVST balance after redemption");
        assertEq(USER.balance, userEthBalanceBefore + (redemptionAmount * currentPrice / 1e18), "Incorrect ETH balance after redemption");
        
        console.log("\n=== Redemption Complete ===");
    }
} 