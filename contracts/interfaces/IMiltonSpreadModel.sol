// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./types/IporTypes.sol";

/// @title Interface for interaction with Milton Spread Model smart contract.
interface IMiltonSpreadModel {
    /// @notice Calculates the quote for Pay-Fixed leg.
    /// @param soap SOAP - Sum of All Payouts.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - Milton balance including Stanley's interest and collateral if present
    /// @return quoteValue calculated quote for Pay Fixed leg
    function calculateQuotePayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 quoteValue);

    /// @notice Calculates the quote for Receive-Fixed leg.
    /// @param soap SOAP - Sum of All Payouts.
    /// @param accruedIpor - accrued IPOR at moment of calculation
    /// @param accruedBalance - Milton's balance including Stanley's interest and collateral if present
    /// @return quoteValue calculated quote for Receive-Fixed leg
    function calculateQuoteReceiveFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 quoteValue);

    /// @notice Calculates the spread for Pay-Fixed leg.
    /// @param soap SOAP - Sum of All Payouts.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - Milton's balance including Stanley's interest and collateral if present
    /// @return spreadValue calculated spread for Pay-Fixed leg
    function calculateSpreadPayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 spreadValue);

    /// @notice Calculates the spread for Receive-Fixed leg.
    /// @param soap SOAP - Sum Of All Payouts.
    /// @param accruedIpor - interest accrued by IPOR at the moment of calculation
    /// @param accruedBalance - Milton's balance including Stanley's interest and collateral if present
    /// @return spreadValue calculated spread for Receive-Fixed leg
    function calculateSpreadReceiveFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 spreadValue);
}
