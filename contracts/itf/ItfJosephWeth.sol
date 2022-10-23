// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./ItfJoseph.sol";

contract ItfJosephWeth is ItfJoseph {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
