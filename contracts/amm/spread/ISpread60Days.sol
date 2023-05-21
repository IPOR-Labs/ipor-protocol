// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "contracts/interfaces/types/IporTypes.sol";

interface ISpread60Days {
    /// @notice Calculates the quote value for a fixed 60-day period on the pay-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the pay-fixed side.
    function calculateQuotePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Calculates the quote value for a fixed 60-day period on the receive-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the receive-fixed side.
    function calculateQuoteReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);
}
