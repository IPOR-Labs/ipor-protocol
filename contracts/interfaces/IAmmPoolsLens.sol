// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.20;

import "./types/IporTypes.sol";

/// @title Interface responsible for reading the AMM Pools state and configuration.
interface IAmmPoolsLens {

    /// @dev A struct to represent a pool configuration.
    /// @param asset The address of the asset.
    /// @param decimals The number of decimal places the asset uses.
    /// @param ipToken The address of the ipToken associated with the asset.
    /// @param ammStorage The address of the AMM's storage contract.
    /// @param ammTreasury The address of the AMM's treasury contract.
    /// @param assetManagement The address of the asset management contract.
    struct AmmPoolsLensPoolConfiguration {
        address asset;
        uint256 decimals;
        address ipToken;
        address ammStorage;
        address ammTreasury;
        address assetManagement;
    }

    /// @notice Retrieves the configuration of a specific asset's pool.
    /// @param asset The address of the asset.
    /// @return PoolConfiguration The pool's configuration.
    function getAmmPoolsLensConfiguration(address asset) external view returns (AmmPoolsLensPoolConfiguration memory);

    /// @notice Calculates the ipToken exchange rate.
    /// @dev The exchange rate is a ratio between the Liquidity Pool Balance and the ipToken's total supply.
    /// @param asset The address of the asset.
    /// @return uint256 The ipToken exchange rate for the specific asset, represented in 18 decimals.
    function getIpTokenExchangeRate(address asset) external view returns (uint256);

    /// @notice Retrieves the AmmTreasury balance for a given asset.
    /// @param asset The address of the asset.
    /// @return IporTypes.AmmBalancesMemory The balance of the AMM Treasury.
    function getAmmBalance(address asset) external view returns (IporTypes.AmmBalancesMemory memory);

    /// @notice Returns the contribution of a specific account to the Liquidity Pool.
    /// @param asset The address of the asset.
    /// @param account The address of the account for which to fetch the contribution.
    /// @return uint256 The account's contribution to the Liquidity Pool, represented in 18 decimals.
    function getLiquidityPoolAccountContribution(address asset, address account) external view returns (uint256);

}
