// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./ItfMilton.sol";

contract ItfMiltonDai is ItfMilton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
