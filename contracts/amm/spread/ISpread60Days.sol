// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";

interface ISpread60Days {
    function calculateQuotePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    function calculateQuoteReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);
}
