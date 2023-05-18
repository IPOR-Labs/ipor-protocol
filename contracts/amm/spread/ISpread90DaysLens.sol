// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../../interfaces/types/IporTypes.sol";

interface ISpread90DaysLens {

    function calculatePayFixed90Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue);

    function calculateReceiveFixed90Days(IporTypes.SpreadInputs calldata spreadInputs)
        external
        returns (uint256 quoteValue);

    function spreadFunction90DaysConfig() external pure returns (uint256[] memory);
}
