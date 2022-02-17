// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../libraries/types/DataTypes.sol";
import "../interfaces/IMiltonStorage.sol";

interface IMiltonSpreadModel {
    function calculateQuotePayFixed(
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) external pure returns (uint256 quoteValue);

    function calculateQuoteReceiveFixed(
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) external pure returns (uint256 quoteValue);

    function calculateSpreadPayFixed(
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) external pure returns (uint256 spreadValue);

    function calculateSpreadRecFixed(
        int256 soap,
        DataTypes.AccruedIpor memory accruedIpor,
        DataTypes.MiltonTotalBalanceMemory memory accruedBalance,
        uint256 swapCollateral
    ) external returns (uint256 spreadValue);
}
