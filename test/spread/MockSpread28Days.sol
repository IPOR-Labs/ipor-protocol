// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../contracts/amm/spread/ISpread28Days.sol";

contract MockSpread28Days is ISpread28Days {
    function calculateQuotePayFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue) {
        return 1;
    }

    function calculateQuoteReceiveFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 quoteValue) {
        return 2;
    }
}
