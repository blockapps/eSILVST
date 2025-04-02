> ⚠️ **Disclaimer**: This repository is entirely vibe coded. While we strive for excellence, please use at your own risk.

# eSILVST - Silver-Backed Token System

eSILVST is a silver-backed token system where 1 token represents 1 troy ounce of physical silver. The project implements a robust trading system allowing users to buy and sell tokens using ETH at current market rates.

## Components

### SilverBackToken Contract

A ERC20-compliant token contract with the following features:
- 1:1 backing of tokens with physical silver reserves
- Trader authorization system with minting limits
- Ability to mint and burn tokens while maintaining reserve ratio
- Pause functionality for emergency situations

### SilverTrading Contract

Handles the buying and selling of tokens with ETH:
- Price feeds for silver and ETH (initialized at $29.50/oz for silver, $3,250 for ETH)
- Trading functionality to buy tokens with ETH and sell tokens for ETH
- Trading limits to control how many tokens can be minted
- Automatic price conversion calculations

## Trader Authorization System

The new trader authorization system allows:
- Owner to authorize specific contracts as traders
- Setting and updating minting limits for each trader
- Tracking how much each trader has minted and burned
- Preventing traders from exceeding their limits

## Getting Started

### Prerequisites

- Foundry installed (https://book.getfoundry.sh/)

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Deploy

```shell
$ forge script script/Deploy.s.sol:Deploy --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## Key Features

- **Silver Backing**: Every token is backed by 1 troy ounce of silver.
- **Trader Authorization**: Only authorized contracts can mint tokens within defined limits.
- **Reserve Ratio**: The system maintains a proper reserve ratio at all times.
- **Market Price Trading**: Buy and sell tokens at current market prices.

## Project Structure

- `src/`: Smart contracts
  - `SilverBackToken.sol`: Main token contract
  - `SilverTrading.sol`: Trading contract
  - `SilverPriceFeed.sol`: Price feed for silver (maintained from original implementation)
- `test/`: Test files for the contracts
- `script/`: Deployment and demo scripts

## Overview

eSILVST tokens are 1:1 backed by physical silver reserves, with each token representing one troy ounce of silver. The system is designed to maintain full collateralization while providing seamless trading capabilities through smart contracts.

### Key Features

- **Full Silver Backing**: Each eSILVST token is backed by 1 troy ounce of physical silver
- **Real-time Price Updates**: Integration with silver price feeds for accurate market pricing
- **Decentralized Trading**: Direct buy/sell functionality through smart contracts
- **Transparent Reserves**: Public verification of silver reserves
- **Uniswap V3 Integration**: Deep liquidity pools for efficient trading

## Architecture

### Core Components

1. **SilverBackToken (eSILVST)**
   - ERC20 token representing physical silver
   - Tracks total supply and silver reserves
   - Implements minting and burning functionality

2. **SilverTraderV2**
   - Handles buy/sell operations
   - Manages ETH/silver conversions
   - Integrates with price feeds

3. **SilverPriceFeed**
   - Provides real-time silver price data
   - Supports multiple price sources
   - Includes mock implementation for testing

4. **SilverUniswapPool**
   - Manages liquidity pools on Uniswap V3
   - Handles price impact and slippage
   - Provides additional trading venue

### Technical Stack

- **Smart Contracts**: Solidity 0.8.20
- **Development Framework**: Foundry
- **Testing**: Forge
- **Dependencies**:
  - OpenZeppelin Contracts
  - Uniswap V3 Core
  - Uniswap V3 Periphery

## Security

- All contracts are audited
- Full test coverage
- Time-locked admin functions
- Pausable functionality for emergency situations
- Regular reserve verification

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.