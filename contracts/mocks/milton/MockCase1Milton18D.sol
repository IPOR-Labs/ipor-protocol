// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MockCase1Milton.sol";

contract MockCase1Milton18D is MockCase1Milton {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporRiskManagementOracle) MockCase1Milton(iporRiskManagementOracle) {}

    function _getDecimals() internal view virtual override returns (uint256) {
        return 18;
    }
}
