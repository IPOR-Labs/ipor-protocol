// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../libraries/Constants.sol";
import "../../libraries/math/IporMath.sol";
import "../../security/IporOwnable.sol";
import "../../interfaces/IMiltonSpreadInternal.sol";

abstract contract MiltonSpreadInternal is IporOwnable, IMiltonSpreadInternal {
    using SafeCast for int256;
    using SafeCast for uint256;

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

    function _getPayFixedRegionOneBase() internal view virtual returns (int256);

    function _getPayFixedRegionOneSlopeForVolatility() internal view virtual returns (int256);

    function _getPayFixedRegionOneSlopeForMeanReversion() internal view virtual returns (int256);

    function _getPayFixedRegionTwoBase() internal view virtual returns (int256);

    function _getPayFixedRegionTwoSlopeForVolatility() internal view virtual returns (int256);

    function _getPayFixedRegionTwoSlopeForMeanReversion() internal view virtual returns (int256);

    function _getReceiveFixedRegionOneBase() internal view virtual returns (int256);

    function _getReceiveFixedRegionOneSlopeForVolatility() internal view virtual returns (int256);

    function _getReceiveFixedRegionOneSlopeForMeanReversion()
        internal
        view
        virtual
        returns (int256);

    function _getReceiveFixedRegionTwoBase() internal view virtual returns (int256);

    function _getReceiveFixedRegionTwoSlopeForVolatility() internal view virtual returns (int256);

    function _getReceiveFixedRegionTwoSlopeForMeanReversion()
        internal
        view
        virtual
        returns (int256);
}
