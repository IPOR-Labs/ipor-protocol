// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./types/IporTypes.sol";

/// @title Interface for interaction with Milton Spread Model smart contract.
interface IMiltonSpreadModel {
    /// @notice Calculates the quote for Pay-Fixed leg.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - Milton balance including Stanley's interest and collateral if present
    /// @param swapCollateral - collateral amount of the swap
    /// @param swapNotional - notional amount of the swap
    /// @return quoteValue calculated quote for Pay Fixed leg
    function calculateQuotePayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonSwapsBalanceMemory memory accruedBalance,
        uint256 swapCollateral,
        uint256 swapNotional
    ) external view returns (uint256 quoteValue);

    /// @notice Calculates the quote for Receive-Fixed leg.
    /// @param accruedIpor - accrued IPOR at moment of calculation
    /// @param accruedBalance - Milton's balance including Stanley's interest and collateral if present
    /// @return quoteValue calculated quote for Receive-Fixed leg
    function calculateQuoteReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (uint256 quoteValue);

    /// @notice Calculates the spread for Pay-Fixed leg.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - Milton's balance including Stanley's interest and collateral if present
    /// @return spreadValue calculated spread for Pay-Fixed leg
    function calculateSpreadPayFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonSwapsBalanceMemory memory accruedBalance
    ) external view returns (int256 spreadValue);

    /// @notice Calculates the spread for Receive-Fixed leg.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - Milton's balance including Stanley's interest and collateral if present
    /// @return spreadValue calculated spread for Receive-Fixed leg
    function calculateSpreadReceiveFixed(
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (int256 spreadValue);
}
