// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ItfStanley.sol";

contract ItfStanleyDai is ItfStanley {
    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
