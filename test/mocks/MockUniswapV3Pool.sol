// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3PoolState} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol";
import {IUniswapV3PoolActions} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol";
import {IUniswapV3PoolEvents} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolEvents.sol";

contract MockUniswapV3Pool is IUniswapV3Pool {
    function slot0() external pure override returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked) {
        return (0, 0, 0, 0, 0, 0, true);
    }
    
    function feeGrowthGlobal0X128() external pure override returns (uint256) {
        return 0;
    }
    
    function feeGrowthGlobal1X128() external pure override returns (uint256) {
        return 0;
    }
    
    function protocolFees() external pure override returns (uint128 fee0, uint128 fee1) {
        return (0, 0);
    }
    
    function liquidity() external pure override returns (uint128) {
        return 0;
    }
    
    function ticks(int24 tick) external pure override returns (uint128 liquidityGross, int128 liquidityNet, uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128, int56 tickCumulativeOutside, uint160 secondsPerLiquidityOutsideX128, uint32 secondsOutside, bool initialized) {
        return (0, 0, 0, 0, 0, 0, 0, false);
    }
    
    function tickBitmap(int16 wordPos) external pure override returns (uint256) {
        return 0;
    }
    
    function positions(bytes32 key) external pure override returns (uint128 posLiquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1) {
        return (0, 0, 0, 0, 0);
    }
    
    function observations(uint256 index) external pure override returns (uint32 blockTimestamp, int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128, bool initialized) {
        return (0, 0, 0, false);
    }
    
    function initialize(uint160 sqrtPriceX96) external override {}
    
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata data) external override returns (uint256 amount0, uint256 amount1) {
        return (0, 0);
    }
    
    function collect(address recipient, int24 tickLower, int24 tickUpper, uint128 amount0Requested, uint128 amount1Requested) external override returns (uint128 amount0, uint128 amount1) {
        return (0, 0);
    }
    
    function burn(int24 tickLower, int24 tickUpper, uint128 amount) external override returns (uint256 amount0, uint256 amount1) {
        return (0, 0);
    }
    
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data) external override returns (int256 amount0, int256 amount1) {
        return (0, 0);
    }
    
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external override {}
    
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external override {}
    
    function token0() external pure override returns (address) {
        return address(0);
    }
    
    function token1() external pure override returns (address) {
        return address(0);
    }
    
    function fee() external pure override returns (uint24) {
        return 0;
    }
    
    function tickSpacing() external pure override returns (int24) {
        return 0;
    }
    
    function maxLiquidityPerTick() external pure override returns (uint128) {
        return 0;
    }
    
    function factory() external pure override returns (address) {
        return address(0);
    }
    
    function observe(uint32[] calldata secondsAgos) external pure override returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) {
        return (new int56[](secondsAgos.length), new uint160[](secondsAgos.length));
    }
    
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper) external pure override returns (int56 tickCumulativeInside, uint160 secondsPerLiquidityInsideX128, uint32 secondsInside) {
        return (0, 0, 0);
    }
    
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external override {}
    
    function collectProtocol(address recipient, uint128 amount0Requested, uint128 amount1Requested) external override returns (uint128 amount0, uint128 amount1) {
        return (0, 0);
    }
} 