// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

interface IAmmPoolsServiceEth {

    function provideLiquidityStEth(address beneficiary, uint256 assetAmount) external;


    /// @notice Emitted when `from` account provides liquidity (ERC20 token supported by IPOR Protocol) to AmmTreasury Liquidity Pool
    event ProvideStEthLiquidity(
    /// @notice moment when liquidity is provided by `from` account
        uint256 timestamp,
    /// @notice address that provides liquidity
        address from,
    /// @notice address of beneficiary who receives ipToken
        address beneficiary,
    /// @notice AmmTreasury's address where liquidity is received
        address to,
    /// @notice current ipToken exchange rate
    /// @dev value represented in 18 decimals
        uint256 exchangeRate,
    /// @notice amount of asset provided by user to AmmTreasury's liquidity pool
    /// @dev value represented in 18 decimals
        uint256 assetAmount,
    /// @notice amount of ipToken issued to represent user's share in the liquidity pool.
    /// @dev value represented in 18 decimals
        uint256 ipTokenAmount
    );
    }

