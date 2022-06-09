// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./MockCase1Milton.sol";

contract MockCase1MiltonUsdc is MockCase1Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
