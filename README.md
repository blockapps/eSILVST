> ⚠️ **Disclaimer**: This repository is entirely vibe coded. While we strive for excellence, please use at your own risk.

# eSILVST - Silver-Backed Token System

eSILVST is a silver-backed token system where 1 token represents 1 troy ounce of physical silver. The project implements a robust trading system allowing users to buy and sell tokens using ETH at current market rates.

## Deployed Contracts

The contracts have been successfully deployed and verified on Sepolia testnet. The specific contract addresses are not included here as they may change in future deployments.

Both contracts are verified on Etherscan and can be interacted with directly through the Etherscan interface once deployed.

## Components

### SilverBackToken Contract

A ERC20-compliant token contract with the following features:
- 1:1 backing of tokens with physical silver reserves
- Owner-controlled minting and burning of tokens
- Ability to update physical silver reserves
- Pause functionality for emergency situations

### SilverTrading Contract

Handles the buying and selling of tokens with ETH:
- Price feeds for silver and ETH (initialized at $29.50/oz for silver, $3,250 for ETH)
- Trading functionality to buy tokens with ETH and sell tokens for ETH
- Automatic price conversion calculations
- Pre-funded with tokens and ETH to enable immediate trading

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

### Deploy to Sepolia

Set up environment variables in a `.env` file:
```
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_api_key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

Deploy the contracts:

```shell
# Source environment variables
$ source .env

# Deploy SilverBackToken
$ forge create --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast src/SilverBackToken.sol:SilverBackToken

# Set initial silver reserve (1000 troy ounces)
$ cast send --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY <TOKEN_ADDRESS> "updateSilverReserve(uint256)" 1000

# Deploy SilverTrading (with token address as constructor parameter)
$ forge create --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast src/SilverTrading.sol:SilverTrading --constructor-args <TOKEN_ADDRESS>

# Mint initial tokens to the trading contract (500 tokens)
$ cast send --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY <TOKEN_ADDRESS> "mint(address,uint256)" <TRADING_ADDRESS> 500000000000000000000

# Send ETH to the trading contract for liquidity
$ cast send --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY <TRADING_ADDRESS> --value 0.01ether

# Update prices (optional)
$ cast send --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY <TRADING_ADDRESS> "updatePrices(uint256,uint256)" 2950000000 325000000000
```

### Verify Contracts on Etherscan

```shell
# Verify SilverBackToken
$ forge verify-contract --chain sepolia --watch <TOKEN_ADDRESS> src/SilverBackToken.sol:SilverBackToken --etherscan-api-key $ETHERSCAN_API_KEY

# Verify SilverTrading
$ forge verify-contract --chain sepolia --watch <TRADING_ADDRESS> src/SilverTrading.sol:SilverTrading --constructor-args $(cast abi-encode "constructor(address)" <TOKEN_ADDRESS>) --etherscan-api-key $ETHERSCAN_API_KEY
```

### Interacting with the Contracts

Buy tokens with ETH:
```shell
$ cast send --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY <TRADING_ADDRESS> "buyTokensWithETH()" --value 0.001ether
```

Sell tokens for ETH:
```shell
# First approve the trading contract to spend your tokens
$ cast send --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY <TOKEN_ADDRESS> "approve(address,uint256)" <TRADING_ADDRESS> <AMOUNT>

# Then sell tokens
$ cast send --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY <TRADING_ADDRESS> "sellTokensForETH(uint256)" <AMOUNT>
```

## Key Features

- **Silver Backing**: Every token is backed by 1 troy ounce of silver.
- **Owner Control**: Only the owner can mint tokens and update the silver reserve.
- **Reserve Ratio**: The system maintains a proper reserve ratio at all times.
- **Market Price Trading**: Buy and sell tokens at current market prices.

## Project Structure

- `src/`: Smart contracts
  - `SilverBackToken.sol`: Main token contract
  - `SilverTrading.sol`: Trading contract for direct ETH/token swaps
- `test/`: Test files for the contracts
- `script/`: Deployment and demo scripts

## Overview

eSILVST tokens are 1:1 backed by physical silver reserves, with each token representing one troy ounce of silver. The system is designed to maintain full collateralization while providing seamless trading capabilities through smart contracts.

### Technical Stack

- **Smart Contracts**: Solidity 0.8.20
- **Development Framework**: Foundry
- **Testing**: Forge
- **Dependencies**:
  - OpenZeppelin Contracts

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.