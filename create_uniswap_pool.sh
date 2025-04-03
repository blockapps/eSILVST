#!/bin/bash
set -e

# Script to create a Uniswap V3 pool for eSILVST token and add initial liquidity
# This script performs the following steps:
# 1. Mint tokens to the owner's address
# 2. Create a Uniswap V3 pool
# 3. Initialize the pool with a price
# 4. Approve the Position Manager to spend tokens
# 5. Add liquidity to the pool

# Load environment variables from .env
source .env

# Set variables with defaults that can be overridden by environment variables
TOKEN_ADDRESS=${TOKEN_ADDRESS:-"0x7f40D086Db7715175dFC3e035879dD0a7457796a"}    # eSILVST token address
WETH_ADDRESS=${WETH_ADDRESS:-"0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14"}      # WETH address on Sepolia
UNISWAP_V3_FACTORY=${UNISWAP_V3_FACTORY:-"0x0227628f3F023bb0B980b67D528571c95c6DaC1c"}  # Uniswap V3 Factory
POSITION_MANAGER=${POSITION_MANAGER:-"0x1238536071E1c677A632429e3655c799b22cDA52"}  # Uniswap V3 NonfungiblePositionManager
FEE_TIER=${FEE_TIER:-3000}                                                      # 0.3% fee tier
OWNER_ADDRESS=${OWNER_ADDRESS:-"0x3967321Ef98ef6c100A09653626696f628c5aefA"}     # Owner address to receive tokens
TOKENS_TO_MINT=${TOKENS_TO_MINT:-10}                                            # Number of tokens to mint
TOKENS_FOR_LIQUIDITY=${TOKENS_FOR_LIQUIDITY:-5}                                 # Number of tokens to add as liquidity
ETH_FOR_LIQUIDITY=${ETH_FOR_LIQUIDITY:-0.045}                                   # Amount of ETH to add as liquidity
FUTURE_DEADLINE=${FUTURE_DEADLINE:-4102441200}                                  # Year 2100 timestamp

# Convert token amounts to wei (with 18 decimals)
TOKENS_TO_MINT_WEI=$(echo "${TOKENS_TO_MINT}*10^18" | bc)
TOKENS_FOR_LIQUIDITY_WEI=$(echo "${TOKENS_FOR_LIQUIDITY}*10^18" | bc)

echo "===================================================="
echo "Creating Uniswap V3 Pool for eSILVST Token"
echo "===================================================="
echo "Token Address: $TOKEN_ADDRESS"
echo "Owner Address: $OWNER_ADDRESS"
echo "Uniswap V3 Factory: $UNISWAP_V3_FACTORY"
echo "Position Manager: $POSITION_MANAGER"
echo "Fee Tier: $FEE_TIER (0.3%)"
echo "===================================================="

# Step 1: Mint tokens to the owner's address
echo -e "\n==== Step 1: Minting $TOKENS_TO_MINT eSILVST tokens to owner ===="
cast send $TOKEN_ADDRESS "mint(address,uint256)" $OWNER_ADDRESS $TOKENS_TO_MINT_WEI \
    --rpc-url $SEPOLIA_RPC_URL --private-key $(echo $PRIVATE_KEY | sed 's/^0x//')

# Check token balance
BALANCE=$(cast call $TOKEN_ADDRESS "balanceOf(address)(uint256)" $OWNER_ADDRESS --rpc-url $SEPOLIA_RPC_URL)
BALANCE_DECIMAL=$(echo "scale=2; $BALANCE / 10^18" | bc)
echo "Token balance: $BALANCE_DECIMAL eSILVST"

# Step 2: Create a Uniswap V3 pool
echo -e "\n==== Step 2: Creating Uniswap V3 pool ===="
cast send $UNISWAP_V3_FACTORY "createPool(address,address,uint24)(address)" \
    $TOKEN_ADDRESS $WETH_ADDRESS $FEE_TIER \
    --rpc-url $SEPOLIA_RPC_URL --private-key $(echo $PRIVATE_KEY | sed 's/^0x//')

# Get the pool address
POOL_ADDRESS=$(cast call $UNISWAP_V3_FACTORY "getPool(address,address,uint24)(address)" \
    $TOKEN_ADDRESS $WETH_ADDRESS $FEE_TIER \
    --rpc-url $SEPOLIA_RPC_URL)
echo "Pool created at: $POOL_ADDRESS"

# Step 3: Initialize the pool with a price
echo -e "\n==== Step 3: Initializing pool with price ===="
# Price is approximately 0.009 ETH per token (based on $29.50/oz for silver, $3,250 for ETH)
SQRTPRICE=${SQRTPRICE:-7516243451251437935592414047}
cast send $POOL_ADDRESS "initialize(uint160)" $SQRTPRICE \
    --rpc-url $SEPOLIA_RPC_URL --private-key $(echo $PRIVATE_KEY | sed 's/^0x//')
echo "Pool initialized with price of ~0.009 ETH per eSILVST"

# Step 4: Approve Position Manager to spend tokens
echo -e "\n==== Step 4: Approving Position Manager to spend tokens ===="
cast send $TOKEN_ADDRESS "approve(address,uint256)" $POSITION_MANAGER $TOKENS_FOR_LIQUIDITY_WEI \
    --rpc-url $SEPOLIA_RPC_URL --private-key $(echo $PRIVATE_KEY | sed 's/^0x//')
echo "Approved Position Manager to spend $TOKENS_FOR_LIQUIDITY eSILVST tokens"

# Step 5: Add liquidity to the pool
echo -e "\n==== Step 5: Adding liquidity to the pool ===="
# Parameters for mint:
# token0, token1, fee, tickLower, tickUpper, amount0Desired, amount1Desired, amount0Min, amount1Min, recipient, deadline
TICK_LOWER=${TICK_LOWER:--887220}
TICK_UPPER=${TICK_UPPER:-887220}
cast send $POSITION_MANAGER "mint((address,address,uint24,int24,int24,uint256,uint256,uint256,uint256,address,uint256))" \
    "($TOKEN_ADDRESS,$WETH_ADDRESS,$FEE_TIER,$TICK_LOWER,$TICK_UPPER,$TOKENS_FOR_LIQUIDITY_WEI,${ETH_FOR_LIQUIDITY}000000000000000000,0,0,$OWNER_ADDRESS,$FUTURE_DEADLINE)" \
    --rpc-url $SEPOLIA_RPC_URL --private-key $(echo $PRIVATE_KEY | sed 's/^0x//') --value ${ETH_FOR_LIQUIDITY}ether
echo "Added liquidity: $TOKENS_FOR_LIQUIDITY eSILVST + $ETH_FOR_LIQUIDITY ETH"

echo -e "\n===================================================="
echo "Uniswap V3 pool successfully created!"
echo "===================================================="
echo "Pool Address: $POOL_ADDRESS"
echo "Trade URL: https://app.uniswap.org/#/swap?chain=sepolia&inputCurrency=ETH&outputCurrency=$TOKEN_ADDRESS"
echo "Pool URL: https://app.uniswap.org/#/pool/$POOL_ADDRESS?chain=sepolia"
echo "===================================================="
echo "Your eSILVST token is now tradable on Uniswap V3!" 