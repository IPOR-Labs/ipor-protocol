// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./MockCase2Milton.sol";

contract MockCase2MiltonUsdt is MockCase2Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
