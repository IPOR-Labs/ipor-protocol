// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "contracts/interfaces/types/IporTypes.sol";

interface ISpread28DaysLens {

    /// @notice Calculates the quote value for pay fixed 28-day period on the pay-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the pay-fixed side.
    function calculatePayFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue);

    /// @notice Calculates the quote value for a fixed 28-day period on the receive-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the receive-fixed side.
    function calculateReceiveFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue);

    /// @notice Returns the configuration values for the spread function used in the 28-day imbalance spread calculation.
    /// @return An array of configuration values for the spread function.
    function spreadFunction28DaysConfig() external pure returns (uint256[] memory);
}
