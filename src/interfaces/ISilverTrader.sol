// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ISilverTrader {
    function buySilver() external payable;
    function sellSilver(uint256 amount) external;
    function sbt() external view returns (address);
    function priceFeed() external view returns (address);
    function paused() external view returns (bool);
    function owner() external view returns (address);
} 