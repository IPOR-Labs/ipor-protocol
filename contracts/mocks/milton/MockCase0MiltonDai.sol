// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./MockCase0Milton.sol";

contract MockCase0MiltonDai is MockCase0Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
