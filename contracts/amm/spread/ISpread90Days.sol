// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "../../interfaces/types/IporTypes.sol";

/// @title Spread interface for tenor 90 days service
interface ISpread90Days {
    /// @notice Calculates the quote value for a fixed 90-day period on the pay-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the pay-fixed side.
    function calculateAndUpdateOfferedRatePayFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Calculates the quote value for a fixed 90-day period on the receive-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the receive-fixed side.
    function calculateAndUpdateOfferedRateReceiveFixed90Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);
}
