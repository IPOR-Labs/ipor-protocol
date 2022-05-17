// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./MiltonV2.sol";

contract MiltonUsdcV2 is MiltonV2 {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
