// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./Milton.sol";

contract MiltonDai is Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
