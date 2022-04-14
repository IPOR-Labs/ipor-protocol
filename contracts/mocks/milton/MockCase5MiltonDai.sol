// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./MockCase5Milton.sol";

contract MockCase5MiltonDai is MockCase5Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
