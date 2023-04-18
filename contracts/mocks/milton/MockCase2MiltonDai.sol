// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./MockCase2Milton.sol";

contract MockCase2MiltonDai is MockCase2Milton {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address marketSafetyOracle) MockCase2Milton(marketSafetyOracle) {
    }

    function _getDecimals() internal pure virtual override returns (uint256) {
        return 18;
    }
}
