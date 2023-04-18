// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./ItfMilton.sol";

contract ItfMiltonUsdc is ItfMilton {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address marketSafetyOracle) ItfMilton(marketSafetyOracle) {
    }

    function _getDecimals() internal pure virtual override returns (uint256) {
        return 6;
    }
}
