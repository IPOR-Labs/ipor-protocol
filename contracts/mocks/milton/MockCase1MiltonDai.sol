// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "./MockCase1Milton.sol";

contract MockCase1MiltonDai is MockCase1Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
