// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ISilverPriceFeed {
    function price() external view returns (uint256);
    function updatePrice(uint256 newPrice) external;
    function updatePriceProvider(address newProvider) external;
} 