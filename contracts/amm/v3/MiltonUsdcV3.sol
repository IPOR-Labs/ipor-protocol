// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "./MiltonV3.sol";

contract MiltonUsdcV3 is MiltonV3 {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
