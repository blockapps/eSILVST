// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

contract MockNonfungiblePositionManager is INonfungiblePositionManager {
    uint256 private tokenIdCounter = 1;
    
    function positions(uint256 tokenId) external pure override returns (uint96 nonce, address operator, address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, uint128 tokensOwed0, uint128 tokensOwed1) {
        return (0, address(0), address(0), address(0), 0, 0, 0, 0, 0, 0, 0, 0);
    }
    
    function mint(INonfungiblePositionManager.MintParams calldata params) external payable override returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        tokenId = tokenIdCounter++;
        liquidity = 1e18;
        amount0 = params.amount0Desired;
        amount1 = params.amount1Desired;
    }
    
    function increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams calldata params) external payable override returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        liquidity = 1e18;
        amount0 = params.amount0Desired;
        amount1 = params.amount1Desired;
    }
    
    function decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams calldata params) external payable override returns (uint256 amount0, uint256 amount1) {
        amount0 = 1e18;
        amount1 = 1e18;
    }
    
    function collect(INonfungiblePositionManager.CollectParams calldata params) external payable override returns (uint256 amount0, uint256 amount1) {
        amount0 = params.amount0Max;
        amount1 = params.amount1Max;
    }
    
    function burn(uint256 tokenId) external payable override {}
    
    function createAndInitializePoolIfNecessary(address token0, address token1, uint24 fee, uint160 sqrtPriceX96) external payable override returns (address pool) {
        return address(0);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external override {}
    
    function transferFrom(address from, address to, uint256 tokenId) external override {}
    
    function approve(address to, uint256 tokenId) external override {}
    
    function getApproved(uint256 tokenId) external pure override returns (address) {
        return address(0);
    }
    
    function setApprovalForAll(address operator, bool approved) external override {}
    
    function isApprovedForAll(address owner, address operator) external pure override returns (bool) {
        return false;
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external override {}
    
    function ownerOf(uint256 tokenId) external pure override returns (address) {
        return address(0);
    }
    
    function balanceOf(address owner) external pure override returns (uint256) {
        return 0;
    }
    
    function name() external pure override returns (string memory) {
        return "";
    }
    
    function symbol() external pure override returns (string memory) {
        return "";
    }
    
    function tokenURI(uint256 tokenId) external pure override returns (string memory) {
        return "";
    }
    
    function baseURI() external pure returns (string memory) {
        return "";
    }
    
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return false;
    }
    
    function permit(address spender, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable override {}
    
    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable override {}
    
    function refundETH() external payable override {}
    
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable override {}
    
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return bytes32(0);
    }
    
    function PERMIT_TYPEHASH() external pure override returns (bytes32) {
        return bytes32(0);
    }
    
    function factory() external view override returns (address) {
        return address(0);
    }
    
    function WETH9() external view override returns (address) {
        return address(0);
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
        return 0;
    }
    
    function tokenByIndex(uint256 index) external view override returns (uint256) {
        return 0;
    }
    
    function totalSupply() external view override returns (uint256) {
        return 0;
    }
} 