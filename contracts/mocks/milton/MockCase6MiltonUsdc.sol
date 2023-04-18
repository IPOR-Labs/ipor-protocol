// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MockCase6Milton.sol";

contract MockCase6MiltonUsdc is MockCase6Milton {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address marketSafetyOracle) MockCase6Milton(marketSafetyOracle) {
    }

    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
