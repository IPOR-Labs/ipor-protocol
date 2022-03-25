// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./types/IporTypes.sol";

interface IMiltonSpreadModel {
    /// @notice Returns current version of Milton Spread Model's
    /// @return current Milton Spread Model version
    function getVersion() external pure returns (uint256);

    function calculateQuotePayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 quoteValue);

    function calculateQuoteReceiveFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 quoteValue);

    function calculateSpreadPayFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 spreadValue);

    function calculateSpreadRecFixed(
        int256 soap,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external pure returns (uint256 spreadValue);
}
