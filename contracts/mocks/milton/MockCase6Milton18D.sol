// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MockCase6Milton.sol";

contract MockCase6Milton18D is MockCase6Milton {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporRiskManagementOracle) MockCase6Milton(iporRiskManagementOracle) {}

    function _getDecimals() internal view virtual override returns (uint256) {
        return 18;
    }
}
