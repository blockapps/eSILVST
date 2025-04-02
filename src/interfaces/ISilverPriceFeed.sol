// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISilverPriceFeed {
    // Returns the current price of silver in USD (with 8 decimals)
    function price() external view returns (uint256);
    
    // Updates the price of silver (only owner can call)
    function updatePrice(uint256 newPrice) external;
    
    // Gets the timestamp of the last price update
    function lastUpdated() external view returns (uint256);
} 