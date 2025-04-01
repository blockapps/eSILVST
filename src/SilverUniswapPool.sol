// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SilverBackToken} from "./SilverBackToken.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {ISilverTrader} from "./interfaces/ISilverTrader.sol";
import {ISilverPriceFeed} from "./interfaces/ISilverPriceFeed.sol";

contract SilverUniswapPool is Ownable, Pausable {
    SilverBackToken public immutable sbt;
    ISwapRouter public immutable swapRouter;
    INonfungiblePositionManager public immutable positionManager;
    ISilverPriceFeed public immutable priceFeed;
    
    uint24 public constant POOL_FEE = 3000; // 0.3%
    
    mapping(address => uint256[]) public userPositions;
    
    event PositionMinted(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event PositionIncreased(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event PositionDecreased(uint256 tokenId, uint256 amount0, uint256 amount1);
    event PositionCollected(uint256 tokenId, uint256 amount0, uint256 amount1);
    event PositionBurned(uint256 tokenId);
    event Swapped(address indexed recipient, bool zeroForOne, int256 amount0, int256 amount1);
    
    constructor(
        address _sbt,
        address _priceFeed,
        address _positionManager,
        address _swapRouter
    ) {
        require(_sbt != address(0), "Invalid eSILVST address");
        require(_priceFeed != address(0), "Invalid price feed address");
        require(_positionManager != address(0), "Invalid position manager address");
        require(_swapRouter != address(0), "Invalid swap router address");
        
        sbt = SilverBackToken(_sbt);
        priceFeed = ISilverPriceFeed(_priceFeed);
        positionManager = INonfungiblePositionManager(_positionManager);
        swapRouter = ISwapRouter(_swapRouter);
        
        IERC20(_sbt).approve(_positionManager, type(uint256).max);
    }
    
    function mintPosition(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    ) external payable whenNotPaused returns (uint256 tokenId) {
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: address(sbt),
            token1: address(swapRouter),
            fee: POOL_FEE,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            recipient: msg.sender,
            deadline: deadline
        });
        
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
        (tokenId, liquidity, amount0, amount1) = positionManager.mint{value: amount1Desired}(params);
        
        userPositions[msg.sender].push(tokenId);
        
        emit PositionMinted(tokenId, liquidity, amount0, amount1);
    }
    
    function increaseLiquidity(
        uint256 tokenId,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    ) external payable whenNotPaused returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: tokenId,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            deadline: deadline
        });
        
        (liquidity, amount0, amount1) = positionManager.increaseLiquidity{value: amount1Desired}(params);
        
        emit PositionIncreased(tokenId, liquidity, amount0, amount1);
    }
    
    function decreaseLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 deadline
    ) external whenNotPaused returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            deadline: deadline
        });
        
        (amount0, amount1) = positionManager.decreaseLiquidity(params);
        
        emit PositionDecreased(tokenId, amount0, amount1);
    }
    
    function collect(
        uint256 tokenId,
        uint128 amount0Max,
        uint128 amount1Max
    ) external whenNotPaused returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: msg.sender,
            amount0Max: amount0Max,
            amount1Max: amount1Max
        });
        
        (amount0, amount1) = positionManager.collect(params);
        
        emit PositionCollected(tokenId, amount0, amount1);
    }
    
    function burnPosition(uint256 tokenId) external whenNotPaused {
        positionManager.burn(tokenId);
        
        emit PositionBurned(tokenId);
    }
    
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external whenNotPaused returns (int256 amount0, int256 amount1) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: zeroForOne ? address(sbt) : address(swapRouter),
            tokenOut: zeroForOne ? address(swapRouter) : address(sbt),
            fee: POOL_FEE,
            recipient: recipient,
            deadline: block.timestamp,
            amountIn: uint256(amountSpecified),
            amountOutMinimum: 0,
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });
        
        uint256 amountOut = swapRouter.exactInputSingle(params);
        amount0 = zeroForOne ? -int256(amountSpecified) : int256(amountOut);
        amount1 = zeroForOne ? int256(amountOut) : -int256(amountSpecified);
        
        emit Swapped(recipient, zeroForOne, amount0, amount1);
    }
    
    function getUserPositions(address user) external view returns (uint256[] memory) {
        return userPositions[user];
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    receive() external payable {}
} 