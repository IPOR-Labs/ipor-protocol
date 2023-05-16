// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MockCase3Milton.sol";

contract MockCase3Milton18D is MockCase3Milton {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporRiskManagementOracle) MockCase3Milton(iporRiskManagementOracle) {}

    function _getDecimals() internal view virtual override returns (uint256) {
        return 18;
    }
}
