// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";

interface ISpread28DaysLens {
    function getSupportedAssets() external view returns (address[] memory);

    function calculatePayFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue);

    function calculateReceiveFixed28Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue);

    function spreadFunction28DaysConfig() external pure returns (uint256[] memory);
}
