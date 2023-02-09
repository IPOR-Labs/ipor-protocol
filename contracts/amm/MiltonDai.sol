// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./Milton.sol";

contract MiltonDai is Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
    function _getMaxLeverage() internal view virtual override returns (uint256) {
        return 500 * 1e18;
    }
}
