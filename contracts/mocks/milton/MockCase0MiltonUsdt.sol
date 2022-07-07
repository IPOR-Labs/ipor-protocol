// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./MockCase0Milton.sol";

contract MockCase0MiltonUsdt is MockCase0Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
