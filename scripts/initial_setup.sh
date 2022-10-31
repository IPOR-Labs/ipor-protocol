#!/usr/bin/env bash

## unpause smart contracts
npx hardhat run --network hardhatfork unpause.js

## setup cash
npx hardhat run --network hardhatfork mint_usdt.js
npx hardhat run --network hardhatfork mint_usdc.js
npx hardhat run --network hardhatfork mint_dai.js

## setup approval
npx hardhat run --network hardhatfork approve.js

## provide initial liquidity
npx hardhat run --network hardhatfork provide_liquidity.js