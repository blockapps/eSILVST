#!/bin/bash

# Check for network parameter (mainnet or testnet/sepolia)
NETWORK=${1:-"testnet"}  # Default to testnet if not specified

# Source environment variables
source .env

# Set variables based on network
if [ "$NETWORK" = "mainnet" ]; then
    echo "Running in MAINNET mode - be careful!"
    RPC_URL=$MAINNET_RPC_URL
    TOKEN_ADDRESS=$MAINNET_TOKEN_ADDRESS
    TRADING_ADDRESS=$MAINNET_TRADING_ADDRESS
    PRIVATE_KEY=$MAINNET_PRIVATE_KEY
    API_KEY=$(echo $MAINNET_RPC_URL | cut -d'/' -f5)
else
    echo "Running in TESTNET (Sepolia) mode"
    RPC_URL=$SEPOLIA_RPC_URL
    TOKEN_ADDRESS=$TOKEN_ADDRESS
    TRADING_ADDRESS=$TRADING_ADDRESS
    PRIVATE_KEY=$SEPOLIA_PRIVATE_KEY
    API_KEY=$(echo $SEPOLIA_RPC_URL | cut -d'/' -f5)
fi

# Check if trading address is set
if [ -z "$TRADING_ADDRESS" ]; then
    echo "Error: TRADING_ADDRESS is not set for $NETWORK"
    exit 1
fi

# Fetch silver price from Metals Dev API
echo "Fetching silver price from Metals Dev API..."
silver_price=$(curl -s "https://api.metals.dev/v1/latest?api_key=${METALS_API_KEY}&currency=USD&unit=toz" | grep -o '"silver":[0-9]*\.[0-9]*' | cut -d':' -f2)

# Fetch ETH price from Alchemy API
echo "Fetching ETH price from Alchemy API..."
eth_price=$(curl -s "https://api.g.alchemy.com/prices/v1/$API_KEY/tokens/by-symbol?symbols=ETH" | grep -o '"value":"[0-9]*\.[0-9]*"' | cut -d':' -f2 | tr -d '"')

# Check if prices were fetched successfully
if [ -z "$silver_price" ]; then
    echo "Error: Failed to fetch silver price"
    exit 1
fi

if [ -z "$eth_price" ]; then
    echo "Error: Failed to fetch ETH price"
    exit 1
fi

# Calculate contract values (with 8 decimal places)
silver_price_contract=$(printf "%.0f" $(echo "$silver_price * 10^8" | bc))
eth_price_contract=$(printf "%.0f" $(echo "$eth_price * 10^8" | bc))

# Print current prices
echo "Current Silver Price: $silver_price USD per troy ounce"
echo "Current ETH Price: $eth_price USD"
echo "Contract values: Silver = $silver_price_contract, ETH = $eth_price_contract"

# Update prices in the contract
echo "Updating prices in the SilverTrading contract ($TRADING_ADDRESS) on $NETWORK..."
cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $TRADING_ADDRESS "updatePrices(uint256,uint256)" $silver_price_contract $eth_price_contract

echo "Price update completed!"
