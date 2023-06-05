// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./types/IporTypes.sol";

/// @title Interface for interaction with AmmTreasury Spread Model smart contract.
interface IAmmTreasurySpreadModel {
    /// @notice Calculates the quote for Pay-Fixed leg.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - AmmTreasury balance including AssetManagement's interest and collateral if present
    /// @return quoteValue calculated quote for Pay Fixed leg
    function calculateQuotePayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.AmmBalancesMemory memory accruedBalance
    ) external view returns (uint256 quoteValue);

    /// @notice Calculates the quote for Receive-Fixed leg.
    /// @param accruedIpor - accrued IPOR at moment of calculation
    /// @param accruedBalance - AmmTreasury's balance including AssetManagement's interest and collateral if present
    /// @return quoteValue calculated quote for Receive-Fixed leg
    function calculateQuoteReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.AmmBalancesMemory memory accruedBalance
    ) external view returns (uint256 quoteValue);

    /// @notice Calculates the spread for Pay-Fixed leg.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - AmmTreasury's balance including AssetManagement's interest and collateral if present
    /// @return spreadValue calculated spread for Pay-Fixed leg
    function calculateSpreadPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.AmmBalancesMemory memory accruedBalance
    ) external view returns (int256 spreadValue);

    /// @notice Calculates the spread for Receive-Fixed leg.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - AmmTreasury's balance including AssetManagement's interest and collateral if present
    /// @return spreadValue calculated spread for Receive-Fixed leg
    function calculateSpreadReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.AmmBalancesMemory memory accruedBalance
    ) external view returns (int256 spreadValue);
}
