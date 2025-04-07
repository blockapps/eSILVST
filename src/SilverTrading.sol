// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for the SilverBackToken contract
interface ISilverBackToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    // Removed mint, burn, getTraderMintingAvailable
}

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title SilverTrading
 * @notice Handles buying and selling of eSILVST tokens using ETH
 * @dev Converts between ETH and tokens based on market prices. Requires pre-funding with tokens by the owner.
 */
contract SilverTrading is Ownable {
    ISilverBackToken public silverToken;
    
    // Price feeds (simplified version - in USD with 8 decimals)
    uint256 public silverPriceUSD; // Price of 1 troy ounce of silver in USD (8 decimals)
    uint256 public ethPriceUSD;    // Price of 1 ETH in USD (8 decimals)
    
    // Removed tradingLimit state variable
    
    // Events
    event PricesUpdated(uint256 silverPriceUSD, uint256 ethPriceUSD);
    event TokensToETH(address indexed user, uint256 tokensAmount, uint256 ethAmount);
    event ETHToTokens(address indexed user, uint256 ethAmount, uint256 tokensAmount);
    // Removed TradingLimitUpdated event

    /**
     * @notice Sets up the trading contract with token address and initial prices
     * @param _silverToken Address of the SilverBackToken contract
     * // Removed _tradingLimit parameter
     */
    constructor(address _silverToken) Ownable(msg.sender) {
        silverToken = ISilverBackToken(_silverToken);
        // Removed tradingLimit initialization
        
        // Initialize with realistic market prices as of April 2024
        // $29.50 per troy ounce of silver with 8 decimals
        silverPriceUSD = 2950 * 1e6;
        
        // $3,250 per ETH with 8 decimals
        ethPriceUSD = 325000 * 1e6;
    }
    
    // Removed requestTraderAuthorization function
    
    // Removed updateTradingLimit function
    
    /**
     * @notice Update price feeds (only owner)
     * @param _silverPriceUSD New silver price in USD (8 decimals)
     * @param _ethPriceUSD New ETH price in USD (8 decimals)
     */
    function updatePrices(uint256 _silverPriceUSD, uint256 _ethPriceUSD) external onlyOwner {
        require(_silverPriceUSD > 0, "Silver price must be positive");
        require(_ethPriceUSD > 0, "ETH price must be positive");
        
        silverPriceUSD = _silverPriceUSD;
        ethPriceUSD = _ethPriceUSD;
        
        emit PricesUpdated(_silverPriceUSD, _ethPriceUSD);
    }
    
    // Removed getRemainingMintCapacity function
    
    /**
     * @notice Calculate how many tokens for given ETH amount
     * @param ethAmount Amount of ETH in wei
     * @return Amount of tokens in wei
     */
    function getTokensForETH(uint256 ethAmount) public view returns (uint256) {
        // ethAmount * ethPriceUSD / silverPriceUSD = silver ounces value
        // Adjust for decimals: ethAmount (wei, 18 decimals) * ethPriceUSD (8 decimals) / silverPriceUSD (8 decimals)
        // Result will be in token units (18 decimals)
        if (silverPriceUSD == 0) return 0; // Avoid division by zero
        return (ethAmount * ethPriceUSD) / silverPriceUSD;
    }
    
    /**
     * @notice Calculate how much ETH for given token amount
     * @param tokenAmount Amount of tokens in wei
     * @return Amount of ETH in wei
     */
    function getETHForTokens(uint256 tokenAmount) public view returns (uint256) {
        // tokenAmount * silverPriceUSD / ethPriceUSD = eth value
        // Adjust for decimals: tokenAmount (18 decimals) * silverPriceUSD (8 decimals) / ethPriceUSD (8 decimals)
        // Result will be in wei (18 decimals)
        if (ethPriceUSD == 0) return 0; // Avoid division by zero
        return (tokenAmount * silverPriceUSD) / ethPriceUSD;
    }
    
    /**
     * @notice Buy tokens with ETH
     * @dev Transfers tokens from this contract's balance to the sender.
     */
    function buyTokensWithETH() external payable {
        require(msg.value > 0, "Must send ETH");
        
        uint256 tokensToTransfer = getTokensForETH(msg.value);
        require(tokensToTransfer > 0, "Insufficient ETH amount");
        
        // Check if this contract has enough tokens
        require(silverToken.balanceOf(address(this)) >= tokensToTransfer, "Insufficient token reserves");
        
        // Removed check against remaining capacity
        // Removed mint call
        
        // Transfer tokens from this contract to the user
        require(silverToken.transfer(msg.sender, tokensToTransfer), "Token transfer failed");
        
        emit ETHToTokens(msg.sender, msg.value, tokensToTransfer);
    }
    
    /**
     * @notice Sell tokens for ETH
     * @param tokenAmount Amount of tokens to sell (in wei)
     * @dev Receives tokens into this contract's balance and sends ETH to the user.
     */
    function sellTokensForETH(uint256 tokenAmount) external {
        require(tokenAmount > 0, "Token amount must be positive");
        require(silverToken.balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");
        
        uint256 ethToSend = getETHForTokens(tokenAmount);
        require(ethToSend > 0, "Token amount too small");
        require(address(this).balance >= ethToSend, "Insufficient ETH in contract");
        
        // Transfer tokens from user to this contract first
        require(silverToken.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        
        // Removed burn call - tokens now held by this contract
        
        // Send ETH to user
        (bool success, ) = msg.sender.call{value: ethToSend}("");
        require(success, "ETH transfer failed");
        
        emit TokensToETH(msg.sender, tokenAmount, ethToSend);
    }
    
    /**
     * @notice Allow contract to receive ETH (e.g., for initial funding or top-ups)
     */
    receive() external payable {}
}