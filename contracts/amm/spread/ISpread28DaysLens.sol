// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../interfaces/types/IporTypes.sol";

/// @title Spread interface for tenor 28 days lens
interface ISpread28DaysLens {
    /// @notice Calculates the quote value for pay fixed 28-day period on the pay-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the pay-fixed side.
    function calculateOfferedRatePayFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external view returns (uint256 quoteValue);

    /// @notice Calculates the quote value for a fixed 28-day period on the receive-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the receive-fixed side.
    function calculateOfferedRateReceiveFixed28Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external view returns (uint256 quoteValue);

    /// @notice Returns the configuration values for the spread function used in the 28-day imbalance spread calculation.
    /// @return An array of configuration values for the spread function.
    function spreadFunction28DaysConfig() external pure returns (uint256[] memory);
}
