// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./MockCase3Milton.sol";

contract MockCase3MiltonDai is MockCase3Milton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
