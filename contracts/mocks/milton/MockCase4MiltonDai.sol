// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./MockCase4Milton.sol";

contract MockCase4MiltonDai is MockCase4Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
