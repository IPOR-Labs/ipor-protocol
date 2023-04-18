// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./Milton.sol";

contract MiltonUsdc is Milton {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address marketSafetyOracle) Milton(marketSafetyOracle) {
    }

    function getVersion() external pure virtual override returns (uint256) {
        return 8;
    }

    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
