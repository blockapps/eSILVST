// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ISilverPriceFeed} from "./interfaces/ISilverPriceFeed.sol";

contract SilverPriceFeed is ISilverPriceFeed, Ownable {
    uint256 public override price;
    address private priceProvider;
    
    event PriceUpdated(uint256 newPrice);
    event PriceProviderUpdated(address newProvider);
    
    constructor(uint256 _initialPrice) {
        require(_initialPrice > 0, "Initial price must be positive");
        price = _initialPrice;
        priceProvider = msg.sender;
    }
    
    modifier onlyPriceProvider() {
        require(msg.sender == priceProvider, "Not authorized");
        _;
    }
    
    function updatePrice(uint256 _newPrice) external override onlyOwner {
        require(_newPrice > 0, "New price must be positive");
        price = _newPrice;
        emit PriceUpdated(_newPrice);
    }
    
    function updatePriceProvider(address newProvider) external override onlyOwner {
        require(newProvider != address(0), "Invalid address");
        priceProvider = newProvider;
        emit PriceProviderUpdated(newProvider);
    }
} 