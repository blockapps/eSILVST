// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ISilverPriceFeed} from "./interfaces/ISilverPriceFeed.sol";

contract SilverPriceFeed is ISilverPriceFeed, Ownable {
    uint256 private _price; // Silver price in USD (8 decimals)
    uint256 private _lastUpdated; // Timestamp of last update
    
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    
    constructor(uint256 initialPrice) Ownable(msg.sender) {
        require(initialPrice > 0, "Initial price must be positive");
        _price = initialPrice;
        _lastUpdated = block.timestamp;
    }
    
    function price() external view override returns (uint256) {
        return _price;
    }
    
    function updatePrice(uint256 newPrice) external override onlyOwner {
        require(newPrice > 0, "New price must be positive");
        uint256 oldPrice = _price;
        _price = newPrice;
        _lastUpdated = block.timestamp;
        emit PriceUpdated(oldPrice, newPrice);
    }
    
    function lastUpdated() external view override returns (uint256) {
        return _lastUpdated;
    }
} 