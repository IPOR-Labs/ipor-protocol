// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "./Milton.sol";

contract MiltonDai is Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
