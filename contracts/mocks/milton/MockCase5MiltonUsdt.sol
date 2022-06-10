// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./MockCase5Milton.sol";

contract MockCase5MiltonUsdt is MockCase5Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
