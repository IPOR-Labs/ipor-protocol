// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/math/IporMath.sol";

// TODO: PRZ update values
uint256 constant END_INTERVAL_ONE = 1000;
uint256 constant END_INTERVAL_TWO = 2000;

// Line One Parameters in wand
int256 constant SLPO_ONE = -5000000000000000000;
int256 constant BASE_ONE = 1000000000000000000;

// Line two Parameters in wand
int256 constant SLPO_TWO = -1000000000000000000;
int256 constant BASE_TWO = 1000000000000000000;

library DecayFactorCalculation {
    using SafeCast for uint256;

    //@param variable represent in int, NOT in WAD
    //@dev return value represented in WAD
    function calculate(uint256 timeInterval) internal pure returns (int256 decayFactor) {
        if (timeInterval < END_INTERVAL_ONE) {
            return linearFunction(SLPO_ONE, BASE_ONE, timeInterval.toInt256());
        }

        if (timeInterval < END_INTERVAL_TWO) {
            return linearFunction(SLPO_TWO, BASE_TWO, timeInterval.toInt256());
        }

        decayFactor = 0;
    }

    //@param slope represent in WAD
    //@param base represent in WAD
    //@param variable represent in int, NOT in WAD
    //@dev return value represented in WAD
    function linearFunction(
        int256 slope,
        int256 base,
        int256 variable
    ) internal pure returns (int256) {
        return slope * variable + base;
    }
}
