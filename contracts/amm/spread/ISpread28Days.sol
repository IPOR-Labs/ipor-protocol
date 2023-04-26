// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";



interface ISpread28Days {

    function calculateQuotePayFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (uint256 quoteValue);

    function calculateQuoteReceiveFixed28Days(
        address asset,
        IporTypes.AccruedIpor memory accruedIpor,
        IporTypes.MiltonBalancesMemory memory accruedBalance
    ) external view returns (uint256 quoteValue);
}