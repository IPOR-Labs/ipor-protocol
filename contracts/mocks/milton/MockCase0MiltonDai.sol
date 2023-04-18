// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MockCase0Milton.sol";

contract MockCase0MiltonDai is MockCase0Milton {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address marketSafetyOracle) MockCase0Milton(marketSafetyOracle) {
    }

    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
