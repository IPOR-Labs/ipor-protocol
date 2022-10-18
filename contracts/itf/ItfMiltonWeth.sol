// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./ItfMilton.sol";

contract ItfMiltonWeth is ItfMilton {
    function _getDecimals() internal pure override returns (uint256) {
        return 18;
    }
}
