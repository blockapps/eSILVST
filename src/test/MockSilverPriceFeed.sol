// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {ISilverPriceFeed} from "../interfaces/ISilverPriceFeed.sol";

contract MockSilverPriceFeed is ISilverPriceFeed {
    uint256 public override price;
    uint8 private constant DECIMALS = 18;

    constructor(uint256 _initialPrice) {
        price = _initialPrice;
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }

    function updatePrice(uint256 _newPrice) external override {
        price = _newPrice;
    }

    function updatePriceProvider(address _newProvider) external override {}
} 