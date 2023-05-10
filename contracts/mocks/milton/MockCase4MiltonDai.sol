// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MockCase4Milton.sol";

contract MockCase4MiltonDai is MockCase4Milton {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address iporRiskManagementOracle) MockCase4Milton(iporRiskManagementOracle) {
    }

    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
