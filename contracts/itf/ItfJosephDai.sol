// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./ItfJoseph.sol";

contract ItfJosephDai is ItfJoseph {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
