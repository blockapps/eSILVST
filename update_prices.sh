#!/bin/bash

# Source environment variables
source .env

# Fetch silver price from Metals Dev API
silver_price=$(curl -s "https://api.metals.dev/v1/latest?api_key=${METALS_API_KEY}&currency=USD&unit=toz" | grep -o '"silver":[0-9]*\.[0-9]*' | cut -d':' -f2)

# Fetch ETH price from Alchemy API
eth_price=$(curl -s "https://api.g.alchemy.com/prices/v1/$(echo $SEPOLIA_RPC_URL | cut -d'/' -f5)/tokens/by-symbol?symbols=ETH" | grep -o '"value":"[0-9]*\.[0-9]*"' | cut -d':' -f2 | tr -d '"')

# Calculate contract values (with 8 decimal places)
silver_price_contract=$(printf "%.0f" $(echo "$silver_price * 10^8" | bc))
eth_price_contract=$(printf "%.0f" $(echo "$eth_price * 10^8" | bc))

# Print current prices
echo "Current Silver Price: $silver_price USD per troy ounce"
echo "Current ETH Price: $eth_price USD"
echo "Contract values: Silver = $silver_price_contract, ETH = $eth_price_contract"

# Update prices in the contract
echo "Updating prices in the SilverTrading contract..."
cast send --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY $TRADING_ADDRESS "updatePrices(uint256,uint256)" $silver_price_contract $eth_price_contract
