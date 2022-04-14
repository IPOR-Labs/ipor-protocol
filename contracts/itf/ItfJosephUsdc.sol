// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./ItfJoseph.sol";

contract ItfJosephUsdc is ItfJoseph {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
