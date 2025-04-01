// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SilverBackToken} from "./SilverBackToken.sol";
import {ISilverPriceFeed} from "./interfaces/ISilverPriceFeed.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SilverTraderV2 is Ownable, Pausable {
    SilverBackToken public immutable sbt;
    ISilverPriceFeed public immutable priceFeed;
    
    uint256 public constant SILVER_TO_TOKEN_RATIO = 1e18; // 1 eSILVST = 1 troy ounce of silver
    
    event TokensBought(address indexed buyer, uint256 amount, uint256 price);
    event TokensSold(address indexed seller, uint256 amount, uint256 price);
    event PriceFeedUpdated(address indexed oldFeed, address indexed newFeed);
    
    constructor(
        address _sbt,
        address _priceFeed
    ) {
        require(_sbt != address(0), "Invalid eSILVST address");
        require(_priceFeed != address(0), "Invalid price feed address");
        
        sbt = SilverBackToken(_sbt);
        priceFeed = ISilverPriceFeed(_priceFeed);
    }
    
    function buySilver() public payable whenNotPaused {
        require(msg.value > 0, "Must send ETH to buy silver");
        
        uint256 currentPrice = priceFeed.price();
        uint256 silverAmount = (msg.value * SILVER_TO_TOKEN_RATIO) / currentPrice;
        
        sbt.mint(msg.sender, silverAmount);
        
        emit TokensBought(msg.sender, silverAmount, currentPrice);
    }
    
    function sellSilver(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        uint256 currentPrice = priceFeed.price();
        uint256 ethAmount = (amount * currentPrice) / SILVER_TO_TOKEN_RATIO;
        
        sbt.burn(msg.sender, amount);
        payable(msg.sender).transfer(ethAmount);
        
        emit TokensSold(msg.sender, amount, currentPrice);
    }

    function depositSilver(uint256 amount) external onlyOwner {
        require(sbt.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    function withdrawSilver(uint256 amount) external onlyOwner {
        require(sbt.transfer(msg.sender, amount), "Transfer failed");
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient ETH balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    receive() external payable {
        buySilver();
    }
} 