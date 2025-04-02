// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SilverBackToken} from "./SilverBackToken.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract SilverTrading is Ownable {
    SilverBackToken public silverToken;
    
    // Price feeds (simplified version - in USD with 8 decimals)
    uint256 public silverPriceUSD; // Price of 1 troy ounce of silver in USD (8 decimals)
    uint256 public ethPriceUSD;    // Price of 1 ETH in USD (8 decimals)
    
    // Trading limits
    uint256 public tradingLimit;   // Maximum token amount this contract can mint
    
    // Events
    event PricesUpdated(uint256 silverPriceUSD, uint256 ethPriceUSD);
    event TokensToETH(address indexed user, uint256 tokensAmount, uint256 ethAmount);
    event ETHToTokens(address indexed user, uint256 ethAmount, uint256 tokensAmount);
    event TradingLimitUpdated(uint256 newLimit);
    
    constructor(address _silverToken, uint256 _tradingLimit) Ownable(msg.sender) {
        silverToken = SilverBackToken(_silverToken);
        tradingLimit = _tradingLimit;
        
        // Initialize with realistic market prices as of April 2024
        // $29.50 per troy ounce of silver with 8 decimals
        silverPriceUSD = 2950 * 1e6;
        
        // $3,250 per ETH with 8 decimals
        ethPriceUSD = 325000 * 1e6;
    }
    
    // This function should be called by the token owner to authorize this contract
    function requestTraderAuthorization() external onlyOwner {
        // This is a helper to remind the owner to authorize this contract
        // as a trader on the silver token contract
        emit TradingLimitUpdated(tradingLimit);
    }
    
    // Update trading limit (only owner)
    function updateTradingLimit(uint256 _newLimit) external onlyOwner {
        tradingLimit = _newLimit;
        emit TradingLimitUpdated(_newLimit);
    }
    
    // Update price feeds (only owner)
    function updatePrices(uint256 _silverPriceUSD, uint256 _ethPriceUSD) external onlyOwner {
        require(_silverPriceUSD > 0, "Silver price must be positive");
        require(_ethPriceUSD > 0, "ETH price must be positive");
        
        silverPriceUSD = _silverPriceUSD;
        ethPriceUSD = _ethPriceUSD;
        
        emit PricesUpdated(_silverPriceUSD, _ethPriceUSD);
    }
    
    // Get remaining minting capacity
    function getRemainingMintCapacity() public view returns (uint256) {
        return silverToken.getTraderMintingAvailable(address(this));
    }
    
    // Calculate how many tokens for given ETH amount
    function getTokensForETH(uint256 ethAmount) public view returns (uint256) {
        // ethAmount * ethPriceUSD / silverPriceUSD = silver ounces value
        // Adjust for decimals: ethAmount (wei, 18 decimals) * ethPriceUSD (8 decimals) / silverPriceUSD (8 decimals)
        // Result will be in token units (18 decimals)
        return (ethAmount * ethPriceUSD) / silverPriceUSD;
    }
    
    // Calculate how much ETH for given token amount
    function getETHForTokens(uint256 tokenAmount) public view returns (uint256) {
        // tokenAmount * silverPriceUSD / ethPriceUSD = eth value
        // Adjust for decimals: tokenAmount (18 decimals) * silverPriceUSD (8 decimals) / ethPriceUSD (8 decimals)
        // Result will be in wei (18 decimals)
        return (tokenAmount * silverPriceUSD) / ethPriceUSD;
    }
    
    // Buy tokens with ETH
    function buyTokensWithETH() external payable {
        require(msg.value > 0, "Must send ETH");
        
        uint256 tokensToMint = getTokensForETH(msg.value);
        require(tokensToMint > 0, "Insufficient ETH amount");
        
        // Check against remaining capacity
        uint256 remainingCapacity = getRemainingMintCapacity();
        require(tokensToMint <= remainingCapacity, "Exceeds trading limit");
        
        // Mint tokens to user
        silverToken.mint(msg.sender, tokensToMint);
        
        emit ETHToTokens(msg.sender, msg.value, tokensToMint);
    }
    
    // Sell tokens for ETH
    function sellTokensForETH(uint256 tokenAmount) external {
        require(tokenAmount > 0, "Token amount must be positive");
        require(silverToken.balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");
        
        uint256 ethToSend = getETHForTokens(tokenAmount);
        require(ethToSend > 0, "Token amount too small");
        require(address(this).balance >= ethToSend, "Insufficient ETH in contract");
        
        // Transfer tokens from user to this contract first
        require(silverToken.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        
        // Burn the tokens
        silverToken.burn(address(this), tokenAmount);
        
        // Send ETH to user
        (bool success, ) = msg.sender.call{value: ethToSend}("");
        require(success, "ETH transfer failed");
        
        emit TokensToETH(msg.sender, tokenAmount, ethToSend);
    }
    
    // Allow contract to receive ETH
    receive() external payable {}
} 