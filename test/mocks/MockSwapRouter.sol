// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IPeripheryImmutableState} from "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";

contract MockSwapRouter is ISwapRouter, IPeripheryImmutableState {
    function exactInput(ExactInputParams calldata params) external payable override returns (uint256 amountOut) {
        return 1e18;
    }
    
    function exactInputSingle(ExactInputSingleParams calldata params) external payable override returns (uint256 amountOut) {
        return 1e18;
    }
    
    function exactOutput(ExactOutputParams calldata params) external payable override returns (uint256 amountIn) {
        return 1e18;
    }
    
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable override returns (uint256 amountIn) {
        return 1e18;
    }
    
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {}
    
    function refundETH() external payable {}
    
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable {}
    
    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable {}
    
    function factory() external view override returns (address) {
        return address(0);
    }
    
    function WETH9() external view override returns (address) {
        return address(0);
    }
} 