// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../security/IporOwnable.sol";
import "../../interfaces/IMiltonSpreadInternal.sol";

contract MiltonSpreadInternal is IporOwnable, IMiltonSpreadInternal {
    using SafeCast for int256;
    using SafeCast for uint256;

    int256 internal constant _PAY_FIXED_REGION_ONE_BASE = 1570169440701153;
    int256 internal constant _PAY_FIXED_REGION_ONE_SLOPE_FOR_VOLATILITY = 198788881093494850;
    int256 internal constant _PAY_FIXED_REGION_ONE_SLOPE_FOR_MEAN_REVERSION = -38331366057144010;

    int256 internal constant _PAY_FIXED_REGION_TWO_BASE = 5957385912947852;
    int256 internal constant _PAY_FIXED_REGION_TWO_SLOPE_FOR_VOLATILITY = 422085481190794900;
    int256 internal constant _PAY_FIXED_REGION_TWO_SLOPE_FOR_MEAN_REVERSION = -1044585377149331200;

    int256 internal constant _RECEIVE_FIXED_REGION_ONE_BASE = 237699618248428;
    int256 internal constant _RECEIVE_FIXED_REGION_ONE_SLOPE_FOR_VOLATILITY = 35927957683456455;
    int256 internal constant _RECEIVE_FIXED_REGION_ONE_SLOPE_FOR_MEAN_REVERSION = 10158530403206013;

    int256 internal constant _RECEIVE_FIXED_REGION_TWO_BASE = -493406136001736;
    int256 internal constant _RECEIVE_FIXED_REGION_TWO_SLOPE_FOR_VOLATILITY = -2696690872084165600;
    int256 internal constant _RECEIVE_FIXED_REGION_TWO_SLOPE_FOR_MEAN_REVERSION =
        -923865786926514900;

    function getPayFixedRegionOneBase() external view override returns (int256) {
        return _getPayFixedRegionOneBase();
    }

    function getPayFixedRegionOneSlopeForVolatility() external view override returns (int256) {
        return _getPayFixedRegionOneSlopeForVolatility();
    }

    function getPayFixedRegionOneSlopeForMeanReversion() external view override returns (int256) {
        return _getPayFixedRegionOneSlopeForMeanReversion();
    }

    function getPayFixedRegionTwoBase() external view override returns (int256) {
        return _getPayFixedRegionTwoBase();
    }

    function getPayFixedRegionTwoSlopeForVolatility() external view override returns (int256) {
        return _getPayFixedRegionTwoSlopeForVolatility();
    }

    function getPayFixedRegionTwoSlopeForMeanReversion() external view override returns (int256) {
        return _getPayFixedRegionTwoSlopeForMeanReversion();
    }

    function getReceiveFixedRegionOneBase() external view override returns (int256) {
        return _getReceiveFixedRegionOneBase();
    }

    function getReceiveFixedRegionOneSlopeForVolatility() external view override returns (int256) {
        return _getReceiveFixedRegionOneSlopeForVolatility();
    }

    function getReceiveFixedRegionOneSlopeForMeanReversion()
        external
        view
        override
        returns (int256)
    {
        return _getReceiveFixedRegionOneSlopeForMeanReversion();
    }

    function getReceiveFixedRegionTwoBase() external view override returns (int256) {
        return _getReceiveFixedRegionTwoBase();
    }

    function getReceiveFixedRegionTwoSlopeForVolatility() external view override returns (int256) {
        return _getReceiveFixedRegionTwoSlopeForVolatility();
    }

    function getReceiveFixedRegionTwoSlopeForMeanReversion()
        external
        view
        override
        returns (int256)
    {
        return _getReceiveFixedRegionTwoSlopeForMeanReversion();
    }

    function _getPayFixedRegionOneBase() internal view virtual returns (int256) {
        return _PAY_FIXED_REGION_ONE_BASE;
    }

    function _getPayFixedRegionOneSlopeForVolatility() internal view virtual returns (int256) {
        return _PAY_FIXED_REGION_ONE_SLOPE_FOR_VOLATILITY;
    }

    function _getPayFixedRegionOneSlopeForMeanReversion() internal view virtual returns (int256) {
        return _PAY_FIXED_REGION_ONE_SLOPE_FOR_MEAN_REVERSION;
    }

    function _getPayFixedRegionTwoBase() internal view virtual returns (int256) {
        return _PAY_FIXED_REGION_TWO_BASE;
    }

    function _getPayFixedRegionTwoSlopeForVolatility() internal view virtual returns (int256) {
        return _PAY_FIXED_REGION_TWO_SLOPE_FOR_VOLATILITY;
    }

    function _getPayFixedRegionTwoSlopeForMeanReversion() internal view virtual returns (int256) {
        return _PAY_FIXED_REGION_TWO_SLOPE_FOR_MEAN_REVERSION;
    }

    function _getReceiveFixedRegionOneBase() internal view virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_ONE_BASE;
    }

    function _getReceiveFixedRegionOneSlopeForVolatility() internal view virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_ONE_SLOPE_FOR_VOLATILITY;
    }

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        returns (int256)
    {
        return _RECEIVE_FIXED_REGION_ONE_SLOPE_FOR_MEAN_REVERSION;
    }

    function _getReceiveFixedRegionTwoBase() internal view virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_TWO_BASE;
    }

    function _getReceiveFixedRegionTwoSlopeForVolatility() internal view virtual returns (int256) {
        return _RECEIVE_FIXED_REGION_TWO_SLOPE_FOR_VOLATILITY;
    }

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        returns (int256)
    {
        return _RECEIVE_FIXED_REGION_TWO_SLOPE_FOR_MEAN_REVERSION;
    }
}
