// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";

interface ISpread28Days {
    function calculateQuotePayFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional,
        uint256 maxLeverage,
        uint256 maxLpUtilizationPerLegRate
    ) external returns (uint256 quoteValue);

    function calculateQuoteReceiveFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.SwapsBalanceMemory memory accruedBalance,
        uint256 swapNotional,
        uint256 maxLeverage,
        uint256 maxLpUtilizationPerLegRate
    ) external returns (uint256 quoteValue);
}
