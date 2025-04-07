// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";

/**
 * @title SilverBackToken
 * @notice ERC20 token representing troy ounces of silver
 * @dev Each token represents 1 troy ounce of silver, backed by physical reserves
 */
contract SilverBackToken is ERC20, Ownable, Pausable {
    // Total amount of silver backing the tokens (in troy ounces)
    uint256 public totalSilverReserve;
    
    // Token ratio (1 token = 1 troy ounce with 18 decimals)
    uint256 public constant SILVER_TO_TOKEN_RATIO = 1e18;

    // Events
    event SilverReserveUpdated(uint256 newReserve);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    /**
     * @notice Initializes the token with name and symbol
     */
    constructor() ERC20("eSILVST Token", "eSILVST") Ownable(msg.sender) {}
    
    /**
     * @notice Calculates the current reserve ratio (reserve / supply)
     * @return The reserve ratio with 18 decimals precision
     */
    function getReserveRatio() public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return (totalSilverReserve * SILVER_TO_TOKEN_RATIO * 1e18) / totalSupply();
    }

    /**
     * @notice Mints new tokens to a specified address
     * @dev Only callable by owner, and must maintain the silver backing ratio
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint (in wei)
     */
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        // Check reserve constraint
        require(totalSupply() + amount <= totalSilverReserve * SILVER_TO_TOKEN_RATIO, 
                "Insufficient silver reserve");
        
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @notice Burns tokens from a specified address
     * @dev Only callable by owner
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn (in wei)
     */
    function burn(address from, uint256 amount) external onlyOwner whenNotPaused {
        require(balanceOf(from) >= amount, "Insufficient balance");
        
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }

    /**
     * @notice Updates the total silver reserve amount
     * @dev Only callable by owner, and must maintain minimum backing for existing tokens
     * @param newReserve New silver reserve amount (in troy ounces)
     */
    function updateSilverReserve(uint256 newReserve) external onlyOwner {
        require(newReserve * SILVER_TO_TOKEN_RATIO >= totalSupply(), 
                "New reserve cannot be less than total supply");
        
        totalSilverReserve = newReserve;
        emit SilverReserveUpdated(newReserve);
    }

    /**
     * @notice Pauses all token transfers, mints, and burns
     * @dev Only callable by owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers, mints, and burns
     * @dev Only callable by owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // Override transfer to respect pause state
    function transfer(address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    // Override transferFrom to respect pause state
    function transferFrom(address from, address to, uint256 amount) public virtual override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }
} 