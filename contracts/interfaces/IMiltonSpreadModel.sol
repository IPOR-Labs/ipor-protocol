// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";

/// @title Interface for interaction with Milton Spread Model smart contract.
interface IMiltonSpreadModel {
    /// @notice Returns current version of Milton Spread Model's
    /// @return current Milton Spread Model version
    function getVersion() external pure returns (uint256);

    /// @notice Calculates Quote for Pay Fixed Leg.
    /// @param soap SOAP - Sum Of All Payouts.
    /// @param accruedIpor - accrued IPOR at moment of calculation
    /// @param accruedBalance - accrued Milton balance (includes Stanley interest and collateral if present)
    /// @return quoteValue calculated quote value for Pay Fixed leg
    function calculateQuotePayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 quoteValue);

    /// @notice Calculates Quote for Receive Fixed Leg.
    /// @param soap SOAP - Sum Of All Payouts.
    /// @param accruedIpor - accrued IPOR at moment of calculation
    /// @param accruedBalance - accrued Milton balance (includes Stanley interest and collateral if present)
    /// @return quoteValue calculated quote value for Receive Fixed leg
    function calculateQuoteReceiveFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 quoteValue);

    /// @notice Calculates spread for Pay Fixed Leg.
    /// @param soap SOAP - Sum Of All Payouts.
    /// @param accruedIpor - accrued IPOR at moment of calculation
    /// @param accruedBalance - accrued Milton balance (includes Stanley interest and collateral if present)
    /// @return spreadValue calculated spread value for Pay Fixed leg
    function calculateSpreadPayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 spreadValue);

    /// @notice Calculates spread for Receive Fixed Leg.
    /// @param soap SOAP - Sum Of All Payouts.
    /// @param accruedIpor - accrued IPOR at moment of calculation
    /// @param accruedBalance - accrued Milton balance (includes Stanley interest and collateral if present)
    /// @return spreadValue calculated spread value for Receive Fixed leg
    function calculateSpreadRecFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 spreadValue);
}
