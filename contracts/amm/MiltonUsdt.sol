// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./Milton.sol";

contract MiltonUsdt is Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
