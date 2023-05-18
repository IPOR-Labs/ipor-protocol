// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";

interface ISpread90Days {
    function calculateQuotePayFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    function calculateQuoteReceiveFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);
}
