// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./ItfStanley.sol";

contract ItfStanley6D is ItfStanley {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}