// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "./Milton.sol";

contract MiltonUsdc is Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
