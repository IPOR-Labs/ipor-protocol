// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MockCase0Milton.sol";

contract MockCase0Milton18D is MockCase0Milton {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporRiskManagementOracle) MockCase0Milton(iporRiskManagementOracle) {}

    function _getDecimals() internal view virtual override returns (uint256) {
        return 18;
    }
}
