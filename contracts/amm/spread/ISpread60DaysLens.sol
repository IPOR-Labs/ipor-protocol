// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";

interface ISpread60DaysLens {

    function calculatePayFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue);

    function calculateReceiveFixed60Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue);

    function spreadFunction60DaysConfig() external pure returns (uint256[] memory);
}
