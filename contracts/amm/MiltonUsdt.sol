// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./Milton.sol";

contract MiltonUsdt is Milton {
    function getVersion() external pure virtual override returns (uint256) {
        return 4;
    }

    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
