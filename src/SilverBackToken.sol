// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract SilverBackToken is ERC20, Ownable, Pausable {
    uint256 public totalSilverReserve; // In troy ounces
    uint256 public constant SILVER_TO_TOKEN_RATIO = 1e18; // 1 eSILVST = 1 troy ounce of silver

    event SilverReserveUpdated(uint256 newReserve);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    constructor() ERC20("SilverBack Token", "eSILVST") {}

    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        require(totalSupply() + amount <= totalSilverReserve * SILVER_TO_TOKEN_RATIO, "Insufficient silver reserve");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner whenNotPaused {
        require(balanceOf(from) >= amount, "Insufficient balance");
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }

    function updateSilverReserve(uint256 newReserve) external onlyOwner {
        require(newReserve * SILVER_TO_TOKEN_RATIO >= totalSupply(), "New reserve cannot be less than total supply");
        totalSilverReserve = newReserve;
        emit SilverReserveUpdated(newReserve);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Override transfer to respect pause
    function transfer(address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    // Override transferFrom to respect pause
    function transferFrom(address from, address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    // Get current silver backing ratio
    function getSilverBackingRatio() public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return (totalSilverReserve * SILVER_TO_TOKEN_RATIO) / totalSupply();
    }
} 