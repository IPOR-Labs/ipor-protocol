// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MockCase5Milton.sol";

contract MockCase5MiltonDai is MockCase5Milton {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address marketSafetyOracle) MockCase5Milton(marketSafetyOracle) {
    }

    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
