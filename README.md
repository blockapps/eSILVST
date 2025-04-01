> ⚠️ **Disclaimer**: This repository is entirely vibe coded. While we strive for excellence, please use at your own risk.

# eSILVST - Silver-Backed Digital Token

eSILVST is a decentralized silver-backed token that enables users to trade physical silver exposure through the Ethereum blockchain. Built with a focus on transparency, security, and user experience, eSILVST represents a new way to access precious metals markets.

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

- **Smart Contracts**: Solidity 0.7.6
- **Development Framework**: Foundry
- **Testing**: Forge
- **Dependencies**:
  - OpenZeppelin Contracts
  - Uniswap V3 Core
  - Uniswap V3 Periphery

## Getting Started

### Prerequisites

- Foundry
- Node.js
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/blockapps/eSILVST.git
cd eSILVST
```

2. Install dependencies:
```bash
forge install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

### Testing

Run the test suite:
```bash
forge test
```

### Deployment

Deploy to Sepolia testnet:
```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url ${SEPOLIA_RPC_URL} --broadcast --verify
```

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