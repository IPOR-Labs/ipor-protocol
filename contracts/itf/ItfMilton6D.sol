// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./ItfMilton.sol";

contract ItfMilton6D is ItfMilton {

    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
