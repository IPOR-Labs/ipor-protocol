// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MockCase5Milton.sol";

contract MockCase5Milton6D is MockCase5Milton {
    constructor(address iporRiskManagementOracle) MockCase5Milton(iporRiskManagementOracle) {}

    function _getDecimals() internal view virtual override returns (uint256) {
        return 6;
    }
}
