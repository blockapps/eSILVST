// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";

contract SilverBackToken is ERC20, Ownable, Pausable {
    uint256 public totalSilverReserve; // In troy ounces
    uint256 public constant SILVER_TO_TOKEN_RATIO = 1e18; // 1 eSILVST = 1 troy ounce of silver

    // Trader authorization structure
    struct TraderInfo {
        bool isAuthorized;
        uint256 mintLimit;     // Max amount this trader can mint (in token units)
        uint256 mintedAmount;  // Amount already minted by this trader
        uint256 burnedAmount;  // Amount already burned by this trader
    }
    
    // Mapping of authorized trader contracts to their limits
    mapping(address => TraderInfo) public traders;
    
    event SilverReserveUpdated(uint256 newReserve);
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event TraderAuthorized(address indexed trader, uint256 mintLimit);
    event TraderRevoked(address indexed trader);
    event TraderLimitUpdated(address indexed trader, uint256 newLimit);

    constructor() ERC20("eSILVST Token", "eSILVST") Ownable(msg.sender) {}
    
    // Modifier to check if caller is owner or authorized trader
    modifier onlyOwnerOrTrader() {
        require(owner() == _msgSender() || traders[_msgSender()].isAuthorized, "Caller is not owner or trader");
        _;
    }
    
    // Add a new authorized trader with a minting limit
    function authorizeTrader(address trader, uint256 mintLimit) external onlyOwner {
        require(trader != address(0), "Invalid trader address");
        require(mintLimit > 0, "Mint limit must be positive");
        
        traders[trader].isAuthorized = true;
        traders[trader].mintLimit = mintLimit;
        
        emit TraderAuthorized(trader, mintLimit);
    }
    
    // Update a trader's minting limit
    function updateTraderLimit(address trader, uint256 newLimit) external onlyOwner {
        require(traders[trader].isAuthorized, "Trader not authorized");
        require(newLimit > 0, "Mint limit must be positive");
        
        traders[trader].mintLimit = newLimit;
        
        emit TraderLimitUpdated(trader, newLimit);
    }
    
    // Revoke a trader's authorization
    function revokeTrader(address trader) external onlyOwner {
        require(traders[trader].isAuthorized, "Trader not authorized");
        
        traders[trader].isAuthorized = false;
        
        emit TraderRevoked(trader);
    }

    // Get trader's available minting capacity
    function getTraderMintingAvailable(address trader) public view returns (uint256) {
        if (!traders[trader].isAuthorized) return 0;
        
        uint256 netMinted = traders[trader].mintedAmount > traders[trader].burnedAmount ? 
                            traders[trader].mintedAmount - traders[trader].burnedAmount : 0;
                            
        return traders[trader].mintLimit > netMinted ? 
               traders[trader].mintLimit - netMinted : 0;
    }
    
    // Get current reserve ratio
    function getReserveRatio() public view returns (uint256) {
        if (totalSupply() == 0) return 0;
        return (totalSilverReserve * SILVER_TO_TOKEN_RATIO * 1e18) / totalSupply();
    }

    function mint(address to, uint256 amount) external onlyOwnerOrTrader whenNotPaused {
        // Check reserve constraint
        require(totalSupply() + amount <= totalSilverReserve * SILVER_TO_TOKEN_RATIO, "Insufficient silver reserve");
        
        // Check trader's limit if caller is a trader (not the owner)
        if (_msgSender() != owner()) {
            require(amount <= getTraderMintingAvailable(_msgSender()), "Exceeds trader's minting limit");
            traders[_msgSender()].mintedAmount += amount;
        }
        
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwnerOrTrader whenNotPaused {
        require(balanceOf(from) >= amount, "Insufficient balance");
        
        // Track burned amount for traders
        if (_msgSender() != owner()) {
            traders[_msgSender()].burnedAmount += amount;
        }
        
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
} 