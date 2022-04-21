// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/math/IporMath.sol";

uint256 constant END_INTERVAL_ONE = 419215;
uint256 constant END_INTERVAL_TWO = 1392607;
uint256 constant END_INTERVAL_THREE = 3024000;

// Line One Parameters in wand
int256 constant SLOPE_FACTOR_ONE = -1192708355669;
int256 constant BASE_ONE = 1000000000000000000;

// Line two Parameters in wand
int256 constant SLOPE_FACTOR_TWO = -410935977479;
int256 constant BASE_TWO = 672270580524927104;

// Line three Parameters in wand
int256 constant SLOPE_FACTOR_THREE = -57166749921;
int256 constant BASE_THREE = 179610198759512800;

library DecayFactorCalculation {
    using SafeCast for uint256;
    using SafeCast for int256;

    //@param variable represent in int, NOT in WAD
    //@dev return value represented in WAD
    function calculate(uint256 timeInterval) internal pure returns (uint256 decayFactor) {
        if (timeInterval < END_INTERVAL_ONE) {
            return linearFunction(SLOPE_FACTOR_ONE, BASE_ONE, timeInterval.toInt256()).toUint256();
        }

        if (timeInterval < END_INTERVAL_TWO) {
            return linearFunction(SLOPE_FACTOR_TWO, BASE_TWO, timeInterval.toInt256()).toUint256();
        }

        if (timeInterval < END_INTERVAL_THREE) {
            return
                linearFunction(SLOPE_FACTOR_THREE, BASE_THREE, timeInterval.toInt256()).toUint256();
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
