// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./MockCase1Milton.sol";

contract MockCase1MiltonUsdt is MockCase1Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
