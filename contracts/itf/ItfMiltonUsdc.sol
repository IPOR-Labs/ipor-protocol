// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "./ItfMilton.sol";

contract ItfMiltonUsdc is ItfMilton {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
