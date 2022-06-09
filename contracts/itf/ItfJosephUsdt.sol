// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ItfJoseph.sol";

contract ItfJosephUsdt is ItfJoseph {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
