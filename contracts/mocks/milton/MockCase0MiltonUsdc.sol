// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MockCase0Milton.sol";

contract MockCase0MiltonUsdc is MockCase0Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
