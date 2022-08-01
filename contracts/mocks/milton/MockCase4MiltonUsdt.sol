// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./MockCase4Milton.sol";

contract MockCase4MiltonUsdt is MockCase4Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
