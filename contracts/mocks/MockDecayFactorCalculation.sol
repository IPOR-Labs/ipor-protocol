// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "../oracles/libraries/DecayFactorCalculation.sol";

contract MockDecayFactorCalculation {
    function linearFunction(
        int256 slope,
        int256 base,
        int256 variable
    ) external pure returns (int256 decayFactor) {
        return DecayFactorCalculation.linearFunction(slope, base, variable);
    }
}
